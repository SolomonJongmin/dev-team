# Team

Ownership folders are examples. Adjust them for your project.

Engine: all workers and reviewers use **Codex** (default `gpt-6.1-sol`, override with `CODEX_MODEL`). Only the PL uses Claude Code to save Claude usage. If a Claude worker is essential, get user approval and use `run-claude.sh`.

| Name | Role (`team/roles/`) | Ownership | Engine |
|---|---|---|---|
| Hangyeol (한결) | PL ([CLAUDE.md](CLAUDE.md)) | Briefs, assignments, reviews, merges, releases, user reports | Main Claude Code session |
| Seojin (서진) | Frontend (`developer`) | `web/`, UI tests | Codex |
| Doyun (도윤) | Backend (`developer`) | `server/`, server tests | Codex |
| Jun (준) | Backend (`developer`) | Areas of `server/` that do not overlap with Doyun, DB migrations (write only) | Codex |
| Jiho (지호) | Refactoring (`refactor`) | Improve structure without changing behavior | Codex |
| Taeo (태오) | Architect (`architect`) | Assess structure and define target structure (read-only, only when needed) | Codex |
| Haeun (하은) | QA (`qa`) | E2E checks right after deployment (no state changes) | Codex + browser MCP |
| Ria (리아) | Cross-reviewer (`reviewer`) | Review diffs before merge (read-only) | Codex (`run-review.sh`, read-only) |
| Seoyeon (서연) | Researcher (`researcher`) | Market and technical research; sources + dates required | Codex (web search) |
