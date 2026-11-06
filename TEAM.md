# Team

Repository ownership is under `C:\Users\최종민\projects`. Cross-repository specialists coordinate file assignments with each repository owner.

Engine: all workers and reviewers use **Codex** (default `gpt-6.1-sol`, override with `CODEX_MODEL`). Only the PL uses Claude Code to save Claude usage. If a Claude worker is essential, get user approval and use `run-claude.sh`.

| Name | Role (`team/roles/`) | Ownership | Engine |
|---|---|---|---|
| Eunho (은호) | PL ([CLAUDE.md](CLAUDE.md)) | Briefs, assignments, reviews, merges, releases, user reports | Main Claude Code session |
| Seojin (서진) | Frontend (`developer`) | `intellicore-front` (intelli-core admin UI) | Codex |
| Doyun (도윤) | Backend (`developer`) | `intelli-core` (auth, IAM, audit) | Codex |
| Jun (준) | Backend (`developer`) | `intellicore-mate-backend` | Codex |
| Harin (하린) | Frontend (`developer`) | `intellicore-mate-front` | Codex |
| Minjae (민재) | AI backend (`developer`) | `intellicore-ax-backend` (agentflow, RAG, LLM) | Codex |
| Yuna (유나) | Frontend (`developer`) | `axnexus-front` | Codex |
| Siwoo (시우) | Integration (`developer`) | External-system integration across repos: SAP/Salesforce connectors, per-user delegated credentials, API connector; coordinate with repo owner; never edit a file another worker holds | Codex |
| Daon (다온) | Test automation (`developer`) | E2E/regression/integration tests and test fixtures in any repo; no product code | Codex |
| Geonu (건우) | Dev environments and CI (`developer`) | Per-workspace setup (Gradle Korean-path junctions, Python venvs, npm), Jenkinsfiles, docker-compose; no product code | Codex |
| Jiho (지호) | Refactoring (`refactor`) | Improve structure without changing behavior | Codex |
| Taeo (태오) | Architect (`architect`) | Assess structure and define target structure (read-only, only when needed) | Codex |
| Haeun (하은) | QA (`qa`) | E2E checks right after deployment (no state changes) | Codex + browser MCP |
| Ria (리아) | Cross-reviewer (`reviewer`) | Review diffs before merge (read-only) | Codex (`run-review.sh`, read-only) |
| Dohyun (도현) | Security reviewer (`reviewer`) | 보안 리뷰: 인증·인가·세션/토큰·개인정보 노출·비밀값·입력 검증 (read-only) | Codex (`REVIEWER=도현 run-review.sh`, read-only) |
| Seoyeon (서연) | Researcher (`researcher`) | Market and technical research; sources + dates required | Codex (web search) |

Ria reviews correctness and design; Dohyun reviews security. Authentication, permission, and session/token changes require both reviews before merge.
