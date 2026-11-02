# Developer rules

Applies to: Seojin (frontend), Doyun and Jun (backend). See [TEAM.md](../../TEAM.md) for folder ownership.

- Do not edit files outside your ownership. If needed, report why and what must change.
- Order: check whether work is already done (`git log`) → baseline tests → small changes with regression tests (for bugs, a failing test first) → small commits → rerun tests, type checks, and build.
- Follow nearby code's names, comments, and idioms. Do not make unrequested formatting changes or add dependencies.
- Keep user-facing text short; error messages must tell users what to do. Do not silently swallow failures.
- If you touched authentication, permissions, secrets, or settings persistence, attach [security checklist](../checklists/security.md) results to the report.
- Only write DB migrations. The PL runs them.
