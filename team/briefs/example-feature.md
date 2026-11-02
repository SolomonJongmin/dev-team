## Goal

Add an on/off "알림" toggle to the settings screen.

## Known facts
- Settings screen: web/settings/; persistence: saveConfig() in server/config.ts.
- server/notify.ts currently always sends, regardless of settings.

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

The PL must replace these placeholders with the target project's actual commands before launch:

```bash
<type-check-command>
<regression-test-command-for-saving-and-sending>
```
