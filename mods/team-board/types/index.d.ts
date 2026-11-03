export type TeamBoardJob = { time: string; worker: string; job: string; state: string; report: string; superseded?: boolean }
export type TeamBoardMember = { english: string; name: string; role: string; ownership: string }
export type TeamBoardDecision = { date: string; slug: string; question: string; options: string }
export type TeamBoardSnapshot = { jobs: TeamBoardJob[]; decisions: TeamBoardDecision[]; warnings: string[]; running: string[]; members: string[]; pathMissing?: boolean }
declare module 'claude-code' {
  interface PluginState {
    'team-board': { snapshot: Shaped<TeamBoardSnapshot> }
  }
}
