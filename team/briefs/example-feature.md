## Goal

Add an on/off "알림" toggle to the settings screen.

## Known facts
- Settings screen: web/settings/; persistence: saveConfig() in server/config.ts.
- server/notify.ts currently always sends, regardless of settings.

## Constraints verified (required)
- Replace illustrative facts above with file:line or URL evidence for external/JAR/API contracts and supported policy values; mark unchecked facts Not checked.
- Record auth/cache policy, permitted token paths and PL-assigned migration number where relevant.

## Environment checked by the PL (required, before launch)
- PL ran the baseline command once in this workspace (or a sibling with the same deps) and it started: caches writable, browsers present (Playwright revision), venv/node_modules present. Write the result here. If deps are already installed, do not ask the worker to install again.
- One final instruction per topic (no "run npm ci" in one place and "do not reinstall" in another).

## Contracts available (required for UI/integration work)
- For every screen or call the worker must build: the API path/field and whether it **already exists** (file:line) or is being built in parallel (owner, fixed field names). Never ask for UI that needs an API nobody is building.

## Auth boundaries (required for auth/token/permission work)
- Token rotation before/after, lock waits, caller trust boundary, which identity each call uses. Decide these in the brief, not in review rounds.

## Verification owner (required)
- What the worker verifies, what the PL verifies (Docker/Testcontainers, browser, deployment) and when. The PL closes its part right after the job ends, before the next round.

## Re-review (when this is a review fix)
- Previous report path(s) and base commit; pass `PREV_REPORT=<path>` to run-review.sh.

## Report language
- Korean (code, commands and paths as-is).

## Baseline (required)
- Exact commands and current pass/fail counts: `<command>: <passed>, <failed>` (replace before launch).

## Preflight
- Optional: list exact runtime/dependency/cache-write commands and safe host checks needed. Run first; any failure stops work with `BLOCKED: <reason>` as the report's first line.
- Use workspace TMP/TEMP; no Windows temp or outside-workspace workarounds. Blocked network/install needs require per-job user approval for full access.

## Where (folder, branch)

- Folder: `../myapp-worktrees/notify-toggle`
- Branch: `feat/notify-toggle`

## Do
1. Add notifications.enabled to config (default true).
2. Add one toggle to the settings screen, labeled "알림".
3. notify.ts must not send when enabled=false.
4. Add regression tests for saving and sending.

## Don't

Do not add other options such as per-notification-type settings, or change package.json or lockfiles.

## Done when

Type checks pass, 0 new failures beyond baseline, and the disabled state persists after restart.
Include relevant rejection cases: concurrent save/send races, other tokens/roles, empty/oversized input and missing config (or explain N/A). Report actual loaded test counts; 0 tests/load failures are incomplete.

The PL must replace these placeholders with the target project's actual commands before launch:

```bash
<type-check-command>
<regression-test-command-for-saving-and-sending>
```
