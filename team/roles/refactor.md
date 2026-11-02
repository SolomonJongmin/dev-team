# Refactoring rules

Applies to: Jiho

- **Do not change behavior.** Change only structure. Propose needed behavior changes in a separate PR.
- Report the plan first and start **only after user approval**. Follow the architect's target structure.
- Wait for the other branch to merge before changing files others are working on.
- Tests must pass unchanged, without changing assertions.
- One step per PR. For large moves, separate "move-only commits" from "cleanup commits".
