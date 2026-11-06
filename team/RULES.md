# Common rules

Every worker reads this before starting. Role rules are in [roles/](roles/); this file takes precedence in a conflict. Fill in `<…>` for each project.

## 1. Working practices
- Do not reopen decisions settled by an [ADR](adr/).
- **Do only what the brief says.** Do not add unrequested features, options, or refactoring. Put ideas only in the report as "Proposal (not implemented)".
- Report problems outside scope; do not fix them.
- Do not invent facts. Mark unchecked items "Not checked" and report failed or skipped steps as they are.
- Team language is English: briefs, worker reports, reviews, rules. The PL answers the user in the user's language. Code comments, commit messages, UI text and project docs follow the target repo's own rules (often not English) — check the repo's guide before writing them.
- **Self-check before submission**: run the [security checklist](checklists/security.md). In particular, check what happens with ① simultaneous requests (races between check and execution), ② bypasses through another path or token, ③ an unauthorized role, and ④ failures or missing settings. Report the results. These four defects recur in reviews.

## 1a. Documents live in the repo
- Research, design docs, meeting notes and decision drafts go in the **target repo's `docs/` folder inside your own workspace**: `docs/research/YYYY-MM-DD-<topic>.md`, `docs/plans/…`, `docs/meetings/…`.
- Write them on your task branch like code. They are shared when the PL merges the branch to `main`; anyone else gets them with `git pull`. Do not leave documents only in local folders outside the repo.
- Before starting, `git pull` (the PL's workspace helper fetches and branches from the latest `main`) so you build on documents others already merged.

## 2. Authority
- Workers may only edit and commit in their own workspace. Sandboxed Codex workers have read-only `.git`, so leave changes without committing (include a proposed commit message in the report). The PL commits in the agent's workspace after review and pushes the branch.
- Do not push, merge, deploy, release, change production data, configure external services, or delete data.
- Do not add packages or change lockfiles, build settings, or shared contracts. Report the need (the PL coordinates).

## 3. Git
- One job = one branch = one person; each agent works only in its own workspace. Branches: `feat/…`, `fix/…`, `refactor/…`, `chore/…`.
- End commits with your engine's signature: Codex workers `Co-Authored-By: Codex <noreply@openai.com>`, Claude workers `Co-Authored-By: Claude <noreply@anthropic.com>`.
- Do not overwrite others' work with amend, rebase, or reset. No force push.
- Use only DB migration numbers assigned by the PL in the brief. Parallel jobs choosing their own "next number" collide.
- Edit files only with editing tools (such as apply_patch). Writing source or docs with shell redirection or `Set-Content` can corrupt non-ASCII text. Check the final diff for corrupted characters (`??`, etc.).

## 4. Tests
- Run the baseline before starting and record existing failures. Baseline failures: `<list>`
- Completion: type checks pass + **0 new failures beyond baseline**. Commands: `<type check>`, `<tests>`
- Do not delete, skip, or weaken tests to make them pass.
- **Report test results only as commands actually run and counts** (e.g. `gradle test`: 1,409 tests, 0 failures). Verify new tests actually execute (not 0 tests or a load failure). If unable to run, write "Could not run + error" — that work is not complete.
- Do not stop shared processes such as build daemons or dev servers (other workers use them). Run builds without daemons (`--no-daemon`, etc.).

## 5. Secrets
- Never put tokens, keys, or passwords in logs, reports, or commits. Report only "present/absent".
- Never commit secrets, `.env*`, signing keys, logs, build outputs, or dependency folders.
- Do not execute scripts inside files received from outside.

## 6. Report format (30 lines max)
End each job report with `Memory proposal:` (0–2 evidence-backed lessons, or `None`). After review, the PL appends accepted lessons to the member's `memory.md` and a job row to `history.md`, then commits; workers only propose unless explicitly assigned profile edits. See [profiles](profiles/README.md).

One-line conclusion / work done / changed files and commits / verification commands and results / remaining issues or decisions needed / changes outside the brief ("None" if none).
Use the role's report format if it defines one.

---
## Change log
- 2026-11-06: Codex workspace-write jobs run with network access (opt-out CODEX_NETWORK=0); external content stays untrusted.
- 2026-11-06: Added Dohyun (도현, dohyun) as a read-only security reviewer; security-sensitive diffs require Ria's correctness/design review and Dohyun's security review.
- 2026-11-06: Read-only reviews/jobs no longer block on report path or test execution; launcher saves the final message.
- 2026-11-06: PL renamed 한결 → 은호 (Eunho, id eunho) to avoid colliding with the DESK assistant 한결.
- 2026-11-06: Repository owners assigned; added 하린, 민재, 유나, 시우, 다온, 건우 (personas adapted from agency-agents, MIT).
- 2026-11-03: Per-person profiles preserve identity, workstyle, and evidence-backed memory/history; workers propose lessons and the PL reviews and commits updates.
- 2026-11-02: Documents (research, plans, meetings) live in the target repo's `docs/` in the agent's workspace and are shared by merging to `main`.
- 2026-11-02: Briefs are Markdown (`<slug>.md`); launchers accept .md and .txt.
- 2026-11-02: Persistent per-agent workspaces (agent-ws.sh) replace per-job worktrees (disk use, cleanup).
- Initial version.
- 2026-11-02: Separate commit signatures by engine. Codex sandbox keeps .git read-only even in worktrees (--add-dir does not help) → Codex workers do not commit; the PL commits.
- 2026-11-02 operations retrospective: self-check before submission (races, bypasses, permissions, failures); report only actual test counts; PL assigns migration numbers; edit files only with editing tools (non-ASCII corruption); do not stop shared daemons. Default worker and review engine is Codex (save Claude usage).
- 2026-11-02: Team docs and prompts switched to English to cut token usage; PL replies to the user in the user's language.
