import { atom, read, update } from 'claude-code'
import type { Register } from 'claude-code'
import type { TeamBoardSnapshot } from '../types/index'
import { snapshot, decisionCount, blockedJobs } from './parse'

const normalize = (path: string) => path.replace(/\\/g, '/').replace(/\/+$/, '')
const SETUP = 'dev-team 경로를 설정하세요 (/plugin → team-board → teamDir)'
const board = atom({ plugin: 'team-board', key: 'snapshot' } as const,
  snapshot(undefined, undefined, 0), { shape: 'board-3' })

export const register: Register = (on, options) => {
  let busy = false
  let active = true
  let timer: { cancel(): void } | undefined
  on('session.start', async ($, e, next) => {
    active = true
    timer?.cancel()
    let lastSummary: string | undefined
    let summaryInitialized = false
    const safeRead = async (path: string) => {
      try { return await $.fs.read(path) } catch { return undefined }
    }
    let root = typeof options.teamDir === 'string' ? normalize(options.teamDir.trim()) : ''
    if (!root) {
      const cwd = normalize(e.cwd)
      for (const candidate of [cwd, `${cwd}/dev-team`]) {
        if (await safeRead(`${candidate}/team/STATUS.md`) !== undefined) {
          root = candidate || '/'
          break
        }
      }
    }
    const poll = async () => {
      if (busy || !active) return
      busy = true
      try {
        const base = normalize(root)
        const [status, decisions, team, now] = await Promise.all([
          root ? safeRead(`${base}/team/STATUS.md`) : undefined,
          root ? safeRead(`${base}/team/DECISIONS.md`) : undefined,
          root ? safeRead(`${base}/TEAM.md`) : undefined, $.clock.now(),
        ])
        if (!active) return
        const value: TeamBoardSnapshot = snapshot(status, decisions, now, team)
        if (!root) value.pathMissing = true
        const previous = await read($, board)
        if (!active) return
        if (JSON.stringify(previous) !== JSON.stringify(value)) await update($, board, () => value)
        const count = decisionCount(value)
        const summary = value.running.length || count ? `팀: 진행 ${value.running.length} · 결정 ${count}` : undefined
        if (!summaryInitialized || lastSummary !== summary) {
          $.ui.status(summary)
          lastSummary = summary
          summaryInitialized = true
        }
      } finally { busy = false }
    }
    await $.command.register({ name: 'team', description: '팀 현황 패널 열기' })
    await poll()
    timer = $.clock.every(5000, poll)
    await $.ui.open({ id: 'team-board', title: '팀 현황' })
    return next(e)
  })
  on('session.end', (_, e, next) => {
    active = false
    timer?.cancel()
    return next(e)
  })
  on('command.run', { command: 'team' }, async $ => {
    await $.ui.open({ id: 'team-board', title: '팀 현황' })
    return { text: '팀 현황 패널 열림' }
  })
  on('ui.render', { component: 'Pane', requestId: 'team-board' }, async ($, e) => {
    const { Box, Text } = $.ui.resolve(e)
    const value = await read($, board)
    if (value.pathMissing) return <Box><Text>{SETUP}</Text></Box>
    const decisions = [
      ...value.decisions.map(d => `${d.date} · ${d.slug}\n${d.question}\n${d.options}`),
      ...blockedJobs(value).map(j => `${j.worker} · ${j.job} · blocked — 보고서 확인\n${j.report}`),
    ]
    const done = value.jobs.filter(j => j.state === 'done').slice(-5).reverse()
    return <Box flexDirection="column">
      <Text bold>팀원</Text>
      {(value.members.length ? value.members : ['없음']).map(line => <Text>{line}</Text>)}
      {value.warnings.map(w => <Text>{w}</Text>)}
      <Text bold>진행 중</Text>
      {(value.running.length ? value.running : ['없음']).map(line => <Text>{line}</Text>)}
      <Text bold>내 결정 필요</Text>
      {(decisions.length ? decisions : ['없음']).map(line => <Text>{line}</Text>)}
      <Text bold>최근 완료</Text>
      {(done.length ? done.map(j => `${j.worker} · ${j.job} · ${j.time}`) : ['없음']).map(line => <Text>{line}</Text>)}
    </Box>
  })
}
