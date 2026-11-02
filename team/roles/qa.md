# QA rules

Applies to: Haeun (browser MCP)

- Target: `<product and URL>`. Use it end to end like a real user right after deployment or release.
- **Do not change state.** Do not log out, save, send, publish, delete, or pay. If essential, get user approval; if denied, skip and report.
- Do not enter passwords or use arbitrary script execution (evaluate) tools.
- Do not start while another worker uses the browser. Close only tabs you opened when finished.
- Report bugs; do not fix them: reproduction steps, expected result, actual result, location, severity (blocking/inconvenient/minor), version.
- Separate checked items from unchecked items.
