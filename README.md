# dev-team — Claude Code + Codex multi-agent development team

One **PL (main Claude Code session)** assigns work to **Codex workers**.
These rules and launch scripts were generalized from use in real product development.

## Contents
| File | Purpose |
|---|---|
| [TEAM.md](TEAM.md) | Members and ownership |
| [CLAUDE.md](CLAUDE.md) | PL rules (Claude Code reads this automatically in this folder) |
| [team/RULES.md](team/RULES.md) | Rules for all workers |
| [team/roles/](team/roles/) | Role rules |
| [team/checklists/security.md](team/checklists/security.md) | Security checklist before submission |
| [team/adr/](team/adr/) | User-approved decisions |
| [team/bin/](team/bin/) | `run-codex.sh` / `run-claude.sh` (launch workers), `run-review.sh` (cross-review), `wait-job.sh` (wait for completion) |
| [team/briefs/](team/briefs/) | Briefs (with an example) |
| `team/STATUS.md` | Status board (updated by launchers) |

## Usage

### Requirements

- [Claude Code](https://claude.com/claude-code) for the PL, installed and signed in.
- Node.js/npm for Codex CLI: `npm i -g @openai/codex`, then `codex login`.
- Git and GitHub CLI (`gh`); run `gh auth login` for GitHub operations.
- On Windows, run the commands below in Git Bash.

### Setup

```bash
git clone https://github.com/SolomonJongmin/dev-team.git
cd dev-team
```

Fill the ownership areas in [TEAM.md](TEAM.md) for your project. Replace the
`<…>` placeholders in `team/RULES.md` with baseline failures and type-check/test
commands, or supply those details in every brief. Registering a Claude Code skill
for this team is optional; opening Claude Code in this folder is enough.

### Starting the PL

Open Claude Code in this folder, or in the target repository with this folder
referenced, and say **"work as this team"** ("이 팀 구성으로 일해줘").
The PL replies in the user's language; team files are English.

### One job, step by step

Run launchers from this team's root folder. Replace angle-bracket placeholders
with real values; quote paths containing spaces. `<repo>` is the target repository.

1. Write `team/briefs/<slug>.txt` with the editing tool; start from
   [example-feature.txt](team/briefs/example-feature.txt). Include the goal, known
   facts, folder/branch, PL-assigned migration number (if any), forbidden changes,
   and done criteria with exact type-check/test commands and baseline counts.
2. The PL updates remote refs and creates a dedicated worktree:

   ```bash
   git -C <repo> fetch origin
   git -C <repo> worktree add <repo>-worktrees/<slug> -b feat/<slug>
   ```

   For read-only investigation, use this instead of the second command:

   ```bash
   git -C <repo> worktree add --detach <repo>-worktrees/<slug> origin/main
   ```

3. Ask the PL to launch the worker as a background task with a completion
   notification. A bare shell background job does not notify the PL session.
   Use an English name and a role filename without `.md` (for example, `developer`):

   ```bash
   team/bin/run-codex.sh <name> <role> <worktree> team/briefs/<slug>.txt [--search]
   ```

   `<worktree>` is the path created above. Omit `[--search]`, or replace it with
   `--search` to enable web search. For example:

   ```bash
   team/bin/run-codex.sh Doyun developer ../myapp-worktrees/notify-toggle team/briefs/notify-toggle.txt
   ```

4. Before launching dependent jobs, wait for earlier jobs, then inspect their
   final status and reports. The wait script waits for completion, not success:

   ```bash
   team/bin/wait-job.sh <slug>...
   ```

   Replace `<slug>...` with one or more space-separated brief slugs.
5. Read `team/reports/<date>-<name>-<slug>.md`, inspect the diff, and rerun the
   brief's tests yourself. For example:

   ```bash
   git -C <worktree> diff
   git -C <worktree> diff --check
   ```

   The PL must see actual executed test counts and baseline comparisons.
6. Cross-review security, permissions, persistence, and lifecycle changes (and
   other changes as needed). Codex leaves changes uncommitted: after inspecting
   them, the PL stages only intended files and makes a checkpoint commit first.
   `run-review.sh` reads `<base>...HEAD`; it cannot see uncommitted edits.

   ```bash
   team/bin/run-review.sh <worktree> <base> <slug> ["focus"]
   ```

   Use a base ref such as `origin/main`; omit `["focus"]` or replace it with a
   quoted review instruction. Read `team/reports/<date>-Ria-review-<slug>.md`.
   Send P0–P2 findings back to the worker with that path and "Read the whole
   report first." The PL commits the fixes, then re-reviews, checking previous
   findings first. For review dependencies, wait on `review-<slug>`.
7. Codex workers do not commit in the sandbox. The PL owns commits, merges the
   reviewed branch onto the latest main, runs the full test suite on that result,
   and pushes only after verification. Follow `team/RULES.md` for commit signatures.

### Roles and engines

Ownership is defined in `TEAM.md`; the names below are the default team.

| Name | Role | Work |
|---|---|---|
| Hangyeol | PL | Assign, verify, commit, merge, release; main Claude Code session |
| Seojin | `developer` | Frontend and UI tests |
| Doyun | `developer` | Backend and server tests |
| Jun | `developer` | Separate backend areas; write migrations |
| Jiho | `refactor` | Structure without behavior changes |
| Taeo | `architect` | Read-only architecture assessment |
| Haeun | `qa` | Post-deployment E2E; Codex + browser MCP |
| Ria | `reviewer` | Read-only cross-review |
| Seoyeon | `researcher` | Research with sources and dates |

All workers and reviews use Codex by default. Only with user approval, launch a
Claude worker with `team/bin/run-claude.sh <name> <role> <worktree> <brief-file>`.
Changing the review engine to Claude also requires user approval.

### Environment variables

Set these in the launching shell, or prefix a launcher with `NAME=value`.

- `CODEX_MODEL`: default `gpt-6.1-sol`; model for Codex workers and reviews.
- `CODEX_ADD_DIRS`: default empty; semicolon-separated extra writable directories, e.g. `CODEX_ADD_DIRS='/c/build-cache'`; worker sandbox only, never unlocks `.git`.
- `CODEX_FULL_ACCESS`: default `0` (`workspace-write`); `1` bypasses sandbox/approvals for workers, only with user approval in a dedicated worktree.
- `REVIEW_ENGINE`: default `codex`; accepts `codex` or `claude`.
- `REVIEWER`: default `Ria`; reviewer name in status lines and report filenames.
- `CLAUDE_MODEL`: default unset (Claude Code's default); model for Claude workers/reviews.
- `CLAUDE_FULL_ACCESS`: default `0` (`auto`); `1` uses `bypassPermissions` for Claude workers, only with user approval in a dedicated worktree; reviews stay read-only.

### Status board and reports

Launchers append `| time | name | slug | running/done/failed | report path |`
lines to `team/STATUS.md`. Never delete its history; use the last line for each
slug. `done` means the report is nonempty, not that tests passed; `failed` means
the report is empty. Read reports before continuing.
Reports are git-ignored. Briefs are git-ignored except `example-feature.txt`.

### Known pitfalls

- Codex's sandbox keeps `.git` read-only: no commit or fetch; the PL does both.
- Shell writes can corrupt non-ASCII text. Use the editing tool (`apply_patch`)
  for file edits and inspect the diff for corrupted characters.
- Do not stop shared build daemons or dev servers. Use no-daemon builds, such
  as `--no-daemon`, where supported.
- Parallel jobs collide on migration numbers; the PL assigns them in briefs.
- Launch jobs with PL completion notifications so finished work is not missed.
- A worker's "tests pass" is not done until the PL verifies the real numbers.
