---
description: Continues implementation of dependency-ready PLAN.md tasks (at most two parallel-safe Builders)
agent: Orchestrator
---

Continue implementation of `@PLAN.md`.

1. **Preconditions (fail loud, no retry):** Stop if the plan is missing, malformed, unapproved, completed, dependency-blocked, or scope-conflicting with the request.
2. **Select the batch:**
   - If `$ARGUMENTS` names task IDs or requests a serial run, implement exactly that — do not broaden it.
   - Otherwise select the maximum safe eligible set: dependency-ready, approved, explicitly parallel-safe tasks with disjoint declared paths/resources — **at most two**. If disjointness is unclear, run one task or ask me.
3. **Dispatch** one Builder per selected task, each with only its task ID and scope. Builders never edit `PLAN.md`, invoke review, or commit while the batch is active.
4. **Barrier:** Wait for all Builders. If any exhausts recovery (one same-session resume; for Builders one further fresh session), no task in the batch proceeds to review or commit — report and stop.
5. **Finalize sequentially** per task: validation through **Testing** (approved commands only) → task-scoped **CodeReviewer** → return critique to the Builder, at most three rounds → only accepted review sets the task `[x]` → authorize the Builder's **Committer** for that task.

$ARGUMENTS
