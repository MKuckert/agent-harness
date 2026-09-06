---
description: Performs a task-scoped code review through the Orchestrator (CodeReviewer)
agent: Orchestrator
---

Review code changes against `@PLAN.md`.

- Preconditions (fail loud, no retry): a `PLAN.md` must exist **and** the request must name an identifiable task or change scope. There is no vague general review mode.
- Delegate to the **CodeReviewer** for exactly that scope:
  1. All changes strictly align with the documented plan.
  2. Code quality, security, and test coverage requirements are met.
  3. No scope creep has occurred.
- Critique leaves the task incomplete; only an accepted review sets it to `[x]`.

Task / change scope to review:

$ARGUMENTS
