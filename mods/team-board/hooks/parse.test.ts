import { expect, test } from 'claude-code/testing'
import { parseStatus, parseDecisions, snapshot, decisionCount, runningLine, parseTeam, memberLines, memberRows } from './parse'

const team = '| Name | Role | Ownership | Engine |\n|---|---|---|---|\n| Hangyeol (한결) | PL ([x](x)) | Briefs | Claude |\n| Seojin (서진) | Frontend (`developer`) | `web/`, UI tests | Codex |\n| Ria (리아) | Cross-reviewer (`reviewer`) | Review diffs before merge | Codex |'

test('TEAM rows parse names, short roles and short ownership', () => {
  const members = parseTeam(team)
  expect(members.length).toBe(3)
  expect(members[1]).toEqual({ english: 'Seojin', name: '서진', role: '개발', ownership: 'web/' })
  expect(members[2].role).toBe('리뷰')
})

test('members match Korean and English case-insensitively, list every running job and append unknown workers', () => {
  const jobs = parseStatus('| 12:00 | rIA | a | running | r |\n| 12:01 | 리아 | b | running | r |\n| 12:02 | SEOJIN | c | done | r |\n| 12:03 | Guest | d | blocked | r |')
  expect(memberLines(parseTeam(team), jobs, 0)).toEqual([
    '한결 · PL · 이 세션', '서진 · 개발 · web/ · 대기 — 최근: c 12:02',
    '리아 · 리뷰 · [작업 중] a (경과 알 수 없음), b (경과 알 수 없음)', 'Guest (명단 외) · [막힘] d',
  ])
  expect(memberLines(parseTeam(team), [], 0)[1]).toBe('서진 · 개발 · web/ · 대기')
})

test('NUL-prefixed and embedded NUL rows preserve failed and cancelled states', () => {
  const jobs = parseStatus('\0'.repeat(522) + '| 12:00 | A | fail\0ed | failed | r |\n| 12:01 | B | stop | cancelled | r |')
  expect(jobs.length).toBe(2)
  expect(jobs[0].job).toBe('failed')
  expect(jobs[0].state).toBe('failed')
  expect(jobs[1].state).toBe('cancelled')
  expect(memberRows([], jobs, 0).map(r => r.color)).toEqual(['red', 'gray'])
  expect(memberLines([], jobs, 0)).toEqual(['A (명단 외) · [막힘] failed', 'B (명단 외) · [취소] stop'])
})

test('completion badge expires after 30 minutes and rejects future timestamps', () => {
  const jobs = parseStatus('| 2026-11-04 12:00:00 | A | job | done | r |')
  const start = Date.parse('2026-11-04T12:00:00+09:00')
  for (const minutes of [0, 30]) {
    expect(memberRows([], jobs, start + minutes * 60000)[0].color).toBe('cyan')
    expect(memberLines([], jobs, start + minutes * 60000)[0]).toBe('A (명단 외) · [완료] job')
  }
  for (const minutes of [-1, 31]) {
    expect(memberRows([], jobs, start + minutes * 60000)[0].dimColor).toBe(true)
    expect(memberLines([], jobs, start + minutes * 60000)[0]).toBe('A (명단 외) · 대기 — 최근: job 12:00')
  }
  expect(memberRows(parseTeam(team), [], start)[0].color).toBe('magenta')
})

test('unresolved failed jobs stay red until a later running or done base job', () => {
  const failure = '| 12:00 | A | review-job | failed | r |\n'
  for (const state of ['cancelled', 'blocked', 'failed']) {
    const board = snapshot(failure + `| 12:01 | A | job-2 | ${state} | r |`, '', 0)
    expect(board.members[0].color).toBe('red')
    expect(decisionCount(board)).toBe(state === 'cancelled' ? 1 : 2)
  }
  for (const state of ['running', 'done']) {
    expect(decisionCount(snapshot(failure + `| 12:01 | A | job-2 | ${state} | r |`, '', 0))).toBe(0)
  }
})

test('only later done or running base-job rows supersede blocked decisions', () => {
  for (const suffix of ['-2', '-2차', '-3차', ' 2차', '-4차']) {
    for (const state of ['done', 'running']) {
      expect(decisionCount(snapshot(`| 23:00 | Ria | review-cli-auth-fixes | blocked | r |\n| 01:00 | 준 | cli-auth-fixes${suffix} | ${state} | r |`, '', 0))).toBe(0)
    }
  }
  for (const rows of [
    '| 12:00 | A | job | blocked | r |',
    '| 11:00 | A | job-2 | done | r |\n| 12:00 | A | review-job | blocked | r |',
    '| 12:00 | A | job | blocked | r |\n| 13:00 | A | job-2 | cancelled | r |',
    '| 12:00 | A | job | blocked | r |\n| 13:00 | A | other-2 | done | r |',
  ]) expect(decisionCount(snapshot(rows, '', 0))).toBe(1)
})

test('both time formats and Korean job names survive parsing', () => {
  const jobs = parseStatus('| 09:30 | 준 | 작업 | running | r |\n| 2026-11-03 11:22:44 | Ria | review-cli-auth-fixes-2차 | done | r2 |')
  expect(jobs.length).toBe(2)
  expect(jobs[0].time).toBe('09:30')
  expect(jobs[1].job).toBe('review-cli-auth-fixes-2차')
})
test('latest row wins even when its timestamp sorts earlier', () => {
  const jobs = parseStatus('| 23:00 | A | job | running | r |\n| 01:00 | B | job | blocked | r2 |')
  expect(jobs.length).toBe(1)
  expect(jobs[0].state).toBe('blocked')
  expect(jobs[0].report).toBe('r2')
})
test('blocked jobs count as decisions and resolved jobs do not', () => {
  expect(decisionCount(snapshot('| 12:00 | A | job | blocked | r |', '', 0))).toBe(1)
  expect(decisionCount(snapshot('| 12:00 | A | job | blocked | r |\n| 12:01 | A | job | done | r |', '', 0))).toBe(0)
})
test('pending decisions include all fields and ignore checked items', () => {
  const list = parseDecisions('- [ ] 2026-11-03 | 선택 | 질문 | A / B\n- [x] 2026-11-03 | closed | q | o')
  expect(list.length).toBe(1)
  expect(list[0]).toEqual({ date: '2026-11-03', slug: '선택', question: '질문', options: 'A / B' })
})
test('missing files produce warnings and empty results', () => {
  const value = snapshot(undefined, undefined, 0)
  expect(value.warnings.length).toBe(3)
  expect(value.jobs.length).toBe(0)
  expect(value.decisions.length).toBe(0)
})
test('dated jobs show elapsed minutes and stale marker only beyond two hours', () => {
  const job = parseStatus('| 2026-11-03 10:00:00 | A | j | running | r |')[0]
  expect(runningLine(job, Date.parse('2026-11-03T12:00:00+09:00')).includes('오래됨?')).toBe(false)
  expect(runningLine(job, Date.parse('2026-11-03T12:01:00+09:00')).includes('121분 · 오래됨?')).toBe(true)
  expect(runningLine({ ...job, time: '10:00' }, Date.parse('2026-11-03T12:01:00+09:00')).includes('경과 알 수 없음')).toBe(true)
})
