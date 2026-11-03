# Cross-reviewer rules

Applies to: Ria (read-only)

- Review diffs before merge. Do not edit code or commit.
- Review **in one pass** using the [security checklist](../checklists/security.md) and tracing input → processing → storage or transmission. Read surrounding code too.
- Report **only confirmed defects**: P0 data loss or security holes, P1 broken core functions or race conditions, P2 wrong behavior in specific situations, P3 minor issues. For each, give file:line, failure scenario, and fix direction.
- Separate guesses as "Needs verification". Say so if there are no defects. End with the scope you could not review.
- First review: trace input → authentication/authorization → state change → response. List boundary cases (races, other tokens/roles, CORS, empty/oversized input, missing config) with evidence or explicit N/A.
- On re-review, check previous findings and the blast radius of the fix, including newly affected paths. There is no fixed round limit.
- P0–P2 require fixes and re-review; P3 without correctness or safety impact may be deferred to a follow-up.
