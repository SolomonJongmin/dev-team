# Security checklist

If you touched authentication, permissions, secrets, settings persistence, or process lifecycles, check before submission and attach a Yes/No/N/A table for each item to the report.

## Secrets
- [ ] Are secrets kept out of logs, error messages, UI, analytics events, and model output? (Including URL queries, title and summary fields)
- [ ] Are credentials kept out of plaintext storage readable by other permission levels (queues, shared tables)?

## Authentication and permissions
- [ ] Are decisions based on server-verified identity and origin, rather than requester claims?
- [ ] Are approvals and responses bound to the actual requesting user and session, so other connections cannot forge them?
- [ ] Do existing bypass paths (direct handlers, admin APIs, permanent grants) receive the same checks as new paths?
- [ ] Are input formats and boundaries (dates, numbers, IDs) validated?

## Race conditions
- [ ] Is it safe if state changes between checking and using it? (Recheck after await; stop after cancellation or expiry)
- [ ] Are late responses prevented from overwriting current state?
- [ ] Are limits and quotas reserved atomically, including concurrent requests?

## Persistence and restart
- [ ] Are untouched fields protected from stale overwrites, and deleted values from being restored?
- [ ] Are save failures passed to the caller?
- [ ] After reconnects, restarts, or timeouts, is old work prevented from interfering with new work?

## Tests
- [ ] Do tests cover actual rejection without mocking the validation function?
- [ ] Have failure, cancellation, and restart paths been tested? Are checks that could not run marked as such?
