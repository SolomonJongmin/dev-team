import { expect, mock, test } from 'claude-code/testing'

const PANE = {
  plugin: 'team-board', component: 'Pane', requestId: 'team-board', surface: 'desktop',
  props: { title: '팀 현황', isFocused: false, bodyColumns: 60, placement: 'dock',
    scroll: { offset: 0, bodyRows: 30 }, view: {} },
} as const

test('open pane follows appended running and done rows without reopening', async ($, on) => {
  const clock = mock.clock(on, { now: Date.parse('2026-11-04T12:00:00+09:00') })
  let status = ''
  let opens = 0
  on('fs.read', (_, e) => ({ value: e.path.endsWith('STATUS.md') ? status : e.path.endsWith('TEAM.md') ? '| Seojin (서진) | Frontend (`developer`) | `web/` | Codex |' : '' }))
  on('command.register', () => ({ value: { command: 'team' } }))
  on('ui.open', () => { opens++; return { value: { isPlaced: true } } })
  on('ui.status', () => ({ value: undefined }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })
  const ui = await $.ui.mount(PANE)
  expect((await ui.find({ type: 'Text', text: /서진 · 개발/ }))?.text).toBe('서진 · 개발 · web/ · 대기')
  expect((await ui.find({ type: 'Text', text: /서진 · 개발/ }))?.props.dimColor).toBe(true)
  status += '| 2026-11-04 12:00:00 | 서진 | live-job | running | r |\n'
  await clock.advance(5000)
  expect((await ui.find({ type: 'Text', text: /\[작업 중\]/ }))?.text).toBe('서진 · 개발 · web/ · [작업 중] live-job (0분)')
  expect((await ui.find({ type: 'Text', text: /\[작업 중\]/ }))?.props.color).toBe('green')
  status += '| 2026-11-04 12:00:05 | 서진 | live-job | done | r |\n'
  await clock.advance(5000)
  expect((await ui.find({ type: 'Text', text: /\[완료\]/ }))?.text).toBe('서진 · 개발 · web/ · [완료] live-job')
  expect((await ui.find({ type: 'Text', text: /\[완료\]/ }))?.props.color).toBe('cyan')
  expect(await ui.find({ type: 'Text', text: /\[작업 중\]/ })).toBe(undefined)
  status += '| 2026-11-04 12:00:10 | 서진 | live-job | failed | r |\n'
  await clock.advance(5000)
  expect((await ui.find({ type: 'Text', text: /\[막힘\]/ }))?.props.color).toBe('red')
  status += '| 2026-11-04 12:00:15 | 서진 | live-job | cancelled | r |\n'
  await clock.advance(5000)
  expect((await ui.find({ type: 'Text', text: /\[취소\]/ }))?.props.color).toBe('gray')
  expect(opens).toBe(1)
  await ui.unmount()
})

for (const fixture of [
  { name: 'configured POSIX path', teamDir: '/workspace/custom/', cwd: '/elsewhere', root: '/workspace/custom' },
  { name: 'configured Windows backslashes', teamDir: 'C:\\workspace\\custom\\', cwd: '/elsewhere', root: 'C:/workspace/custom' },
  { name: 'autodetect cwd before child', teamDir: '', cwd: '/workspace/dev-team/', root: '/workspace/dev-team' },
  { name: 'autodetect Windows cwd child', teamDir: '', cwd: 'C:\\workspace\\', root: 'C:/workspace/dev-team' },
  { name: 'nothing found', teamDir: '', cwd: '/empty', root: undefined },
]) {
  test(fixture.name, { options: { teamDir: fixture.teamDir } }, async ($, on) => {
    mock.clock(on)
    const paths: string[] = []
    const summaries: (string | undefined)[] = []
    on('fs.read', (_, e) => {
      const normalized = e.path.replace(/\\/g, '/')
      const path = fixture.root?.startsWith('/') ? normalized.replace(/^[A-Za-z]:/, '') : normalized
      paths.push(path)
      if (!fixture.root || !path.startsWith(`${fixture.root}/`)) throw new Error('missing')
      return { value: e.path.endsWith('STATUS.md') ? '| 12:00 | Worker | job | running | report.md |' : '' }
    })
    on('command.register', () => ({ value: { command: 'team' } }))
    on('ui.open', () => ({ value: { isPlaced: true } }))
    on('ui.status', (_, e) => { summaries.push(e.text); return { value: undefined } })
    on('session.start', (_, e) => ({ cwd: e.cwd }))
    await $.session.start({ cwd: fixture.cwd, surface: 'desktop', isInteractive: true })
    const ui = await $.ui.mount(PANE)
    if (fixture.root) {
      expect(paths.includes(`${fixture.root}/team/STATUS.md`)).toBe(true)
      expect(paths.includes(`${fixture.root}/team/DECISIONS.md`)).toBe(true)
      expect(paths.includes(`${fixture.root}/TEAM.md`)).toBe(true)
      expect(summaries[0]).toBe('팀: 진행 1 · 결정 0')
      expect(await ui.find({ type: 'Text', text: /dev-team 경로를 설정하세요/ })).toBe(undefined)
      if (fixture.teamDir) expect(paths.length).toBe(3)
      if (fixture.name === 'autodetect cwd before child') expect(paths.some(path => path.includes('/dev-team/dev-team/'))).toBe(false)
    } else {
      expect((await ui.find({ type: 'Text', text: /dev-team 경로를 설정하세요/ }))?.text)
        .toBe('dev-team 경로를 설정하세요 (/plugin → team-board → teamDir)')
      expect(await ui.find({ type: 'Text', text: '팀원' })).toBe(undefined)
      expect(await ui.find({ type: 'Text', text: /읽기 실패/ })).toBe(undefined)
      expect(summaries.length).toBe(1)
      expect(summaries[0]).toBe(undefined)
      expect(paths.length).toBe(2)
    }
    await ui.unmount()
  })
}

test('polling renders jobs, blocked reports and decisions then clears status on recovery', async ($, on) => {
  const clock = mock.clock(on, { now: Date.parse('2026-11-03T12:30:00+09:00') })
  let status = '| 2026-11-03 12:00:00 | 서진 | 작업 | running | r |\n| 12:01 | 준 | 막힘 | blocked | report.md |'
  let decisions = '- [ ] 2026-11-03 | 선택 | 질문 | A / B'
  let reads = 0
  const summaries: (string | undefined)[] = []
  const opens: string[] = []
  let team = '| Seojin (서진) | Frontend (`developer`) | `web/` | Codex |'
  on('fs.read', (_, e) => { reads++; return { value: e.path.endsWith('STATUS.md') ? status : e.path.endsWith('TEAM.md') ? team : decisions } })
  on('command.register', () => ({ value: { command: 'team' } }))
  on('ui.open', (_, e) => { opens.push(e.id); return { value: { isPlaced: true } } })
  on('ui.status', (_, e) => { summaries.push(e.text); return { value: undefined } })
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })
  const ui = await $.ui.mount(PANE)
  expect((await ui.find({ type: 'Text', text: /\[작업 중\] 작업/ }))?.text).toBe('서진 · 개발 · web/ · [작업 중] 작업 (30분)')
  expect((await ui.find({ type: 'Text', text: /보고서 확인/ }))?.text).toBe('준 · 막힘 · blocked — 보고서 확인\nreport.md')
  expect((await ui.find({ type: 'Text', text: /A \/ B/ }))?.text).toBe('2026-11-03 · 선택\n질문\nA / B')
  expect(summaries[0]).toBe('팀: 진행 1 · 결정 2')
  await clock.advance(5000)
  expect(reads).toBe(7)
  expect(summaries.length).toBe(1)
  status = ''; decisions = ''; team = '| Ria (리아) | Cross-reviewer (`reviewer`) | Review | Codex |'
  await clock.advance(5000)
  expect(summaries.length).toBe(2)
  expect(summaries[1]).toBe(undefined)
  expect((await ui.find({ type: 'Text', text: /리아 · 리뷰/ }))?.text).toBe('리아 · 리뷰 · Review · 대기')
  await $.command.run({ command: 'team', args: '' })
  expect(opens.length).toBe(2)
  await ui.unmount()
})

test('unreadable files render actionable warnings without throwing', { options: { teamDir: '/workspace/dev-team' } }, async ($, on) => {
  mock.clock(on)
  on('fs.read', () => { throw new Error('unreadable') })
  on('command.register', () => ({ value: { command: 'team' } }))
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('ui.status', () => ({ value: undefined }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })
  const ui = await $.ui.mount(PANE)
  expect((await ui.find({ type: 'Text', text: /STATUS.md 읽기 실패/ }))?.text).toBe('경고: STATUS.md 읽기 실패 — 파일과 읽기 권한 확인')
  expect((await ui.find({ type: 'Text', text: /DECISIONS.md 읽기 실패/ }))?.text).toBe('경고: DECISIONS.md 읽기 실패 — 파일과 읽기 권한 확인')
  expect((await ui.find({ type: 'Text', text: /TEAM.md 읽기 실패/ }))?.text).toBe('경고: TEAM.md 읽기 실패 — 파일과 읽기 권한 확인')
  await ui.unmount()
})

test('later resolved round removes the blocked decision from pane and status', async ($, on) => {
  mock.clock(on)
  const summaries: (string | undefined)[] = []
  on('fs.read', (_, e) => ({ value: e.path.endsWith('STATUS.md')
    ? '| 12:00 | Ria | review-job | blocked | old-report.md |\n| 12:01 | Ria | review-job-4차 | done | new-report.md |'
    : e.path.endsWith('TEAM.md') ? '| Ria (리아) | Cross-reviewer (`reviewer`) | Review diffs before merge | Codex |' : '' }))
  on('command.register', () => ({ value: { command: 'team' } }))
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('ui.status', (_, e) => { summaries.push(e.text); return { value: undefined } })
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })
  const ui = await $.ui.mount(PANE)
  expect(await ui.find({ type: 'Text', text: /보고서 확인/ })).toBe(undefined)
  expect(summaries[0]).toBe(undefined)
  expect((await ui.find({ type: 'Text', text: /리아 · 리뷰/ }))?.text).toBe('리아 · 리뷰 · 대기 — 최근: review-job-4차 12:01')
  await ui.unmount()
})
