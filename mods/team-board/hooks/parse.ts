import type { TeamBoardJob, TeamBoardDecision, TeamBoardSnapshot, TeamBoardMember } from '../types/index'

const TIME = /^(?:\d{4}-\d{2}-\d{2} )?(?:[01]\d|2[0-3]):[0-5]\d(?::[0-5]\d)?$/

const baseJob = (name: string) => name.replace(/^review-/, '').replace(/(?:-\d+(?:차)?| \d+차)$/, '')

export function parseTeam(text: string | undefined): TeamBoardMember[] {
  const roles: Record<string, string> = { developer: '개발', refactor: '리팩터링', architect: '설계', qa: 'QA', reviewer: '리뷰', researcher: '리서치', pl: 'PL' }
  return (text ?? '').split(/\r?\n/).flatMap(line => {
    const cells = line.trim().split('|').slice(1, -1).map(s => s.trim())
    const name = /^([^()]+)\s+\(([^()]+)\)$/.exec(cells[0] ?? '')
    if (cells.length !== 4 || !name) return []
    const key = /`(developer|refactor|architect|qa|reviewer|researcher)`|\b(PL)\b/i.exec(cells[1])
    const ownership = cells[2].split(',')[0].replace(/`/g, '').trim()
    return [{ english: name[1].trim(), name: name[2], role: roles[(key?.[1] ?? key?.[2] ?? '').toLowerCase()] ?? cells[1], ownership: ownership.length <= 12 ? ownership : '' }]
  })
}

export function memberLines(members: TeamBoardMember[], jobs: TeamBoardJob[], now: number): string[] {
  return memberRows(members, jobs, now).map(row => row.text)
}

export function memberRows(members: TeamBoardMember[], jobs: TeamBoardJob[], now: number) {
  const row = (prefix: string, badge: string, detail: string, color: 'green' | 'red' | 'cyan' | 'gray' | 'magenta', dimColor = false) =>
    ({ text: prefix + badge + detail, prefix, badge, detail, color, dimColor })
  const matches = (m: TeamBoardMember, worker: string) => [m.english, m.name].some(n => n.toLowerCase() === worker.toLowerCase())
  const roster = [...members]
  for (const job of jobs) if (!roster.some(m => matches(m, job.worker))) {
    roster.push({ english: job.worker, name: job.worker, role: '', ownership: '' })
  }
  return roster.map((m, index) => {
    const label = index < members.length ? [m.name, m.role, m.ownership].filter(Boolean).join(' · ') : `${m.name} (명단 외)`
    if (m.role === 'PL') return row(`${m.name} · `, 'PL', ' · 이 세션', 'magenta')
    const history = jobs.filter(j => matches(m, j.worker))
    const running = history.filter(j => j.state === 'running')
    if (running.length) return row(`${label} · `, '[작업 중]', ` ${running.map(j => `${j.job} (${runningLine(j, now).split(' · ').slice(3).join(' · ')})`).join(', ')}`, 'green')
    const latest = history[history.length - 1]
    const unresolved = history.filter(j => (j.state === 'blocked' || j.state === 'failed') && !j.superseded)
    if (unresolved.length) return row(`${label} · `, '[막힘]', ` ${unresolved.map(j => j.job).join(', ')}`, 'red')
    const age = latest ? now - jobTime(latest.time) : NaN
    if (latest?.state === 'done' && age >= 0 && age <= 30 * 60000) return row(`${label} · `, '[완료]', ` ${latest.job}`, 'cyan')
    if (latest?.state === 'cancelled') return row(`${label} · `, '[취소]', ` ${latest.job}`, 'gray')
    const time = latest?.time.match(/\d{2}:\d{2}/)?.[0]
    return row(`${label} · `, '대기', latest ? ` — 최근: ${latest.job} ${time}` : '', 'gray', true)
  })
}

export function parseStatus(text: string | undefined): TeamBoardJob[] {
  const jobs = new Map<string, TeamBoardJob>()
  for (const line of (text ?? '').split(/\r?\n/)) {
    const cells = line.replace(/\0/g, '').trim().split('|').slice(1, -1).map(s => s.trim())
    if (cells.length !== 5 || !TIME.test(cells[0]) || !cells[2]) continue
    const [time, worker, job, state, report] = cells
    if (state === 'done' || state === 'running') {
      for (const previous of jobs.values()) {
        if ((previous.state === 'blocked' || previous.state === 'failed') && baseJob(previous.job) === baseJob(job)) previous.superseded = true
      }
    }
    // Reinsertion preserves the latest row's position, regardless of timestamps.
    jobs.delete(job)
    jobs.set(job, { time, worker, job, state, report })
  }
  return [...jobs.values()]
}

export function parseDecisions(text: string | undefined): TeamBoardDecision[] {
  const result: TeamBoardDecision[] = []
  for (const line of (text ?? '').split(/\r?\n/)) {
    const match = /^\s*- \[ \] (\d{4}-\d{2}-\d{2})\s*\|\s*([^|]+)\|\s*([^|]+)\|\s*(.+)$/.exec(line)
    if (match) result.push({ date: match[1], slug: match[2].trim(), question: match[3].trim(), options: match[4].trim() })
  }
  return result
}

export function runningLine(job: TeamBoardJob, now: number): string {
  // Legacy HH:MM has no date; do not invent its age or stale status.
  const start = jobTime(job.time)
  const age = now - start
  const elapsed = Number.isFinite(age) && age >= 0 ? `${Math.floor(age / 60000)}분` : '경과 알 수 없음'
  return `${job.worker} · ${job.job} · ${job.time} · ${elapsed}${age > 7200000 ? ' · 오래됨?' : ''}`
}

function jobTime(time: string): number {
  // A legacy time has no date, so neither its age nor recency is known.
  return /^\d{4}-/.test(time) ? Date.parse(time.replace(' ', 'T') + '+09:00') : NaN
}

export function snapshot(status: string | undefined, decisions: string | undefined, now: number, team?: string): TeamBoardSnapshot {
  const jobs = parseStatus(status)
  return { jobs, decisions: parseDecisions(decisions), warnings: [
    ...(status === undefined ? ['경고: STATUS.md 읽기 실패 — 파일과 읽기 권한 확인'] : []),
    ...(decisions === undefined ? ['경고: DECISIONS.md 읽기 실패 — 파일과 읽기 권한 확인'] : []),
    ...(team === undefined ? ['경고: TEAM.md 읽기 실패 — 파일과 읽기 권한 확인'] : []),
  ], members: memberRows(parseTeam(team), jobs, now), running: jobs.filter(j => j.state === 'running').map(j => runningLine(j, now)) }
}

export const blockedJobs = (board: TeamBoardSnapshot) => board.jobs.filter(j => (j.state === 'blocked' || j.state === 'failed') && !j.superseded)

export function decisionCount(board: TeamBoardSnapshot): number {
  return board.decisions.length + blockedJobs(board).length
}
