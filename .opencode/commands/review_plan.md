---
description: Reviews the current PLAN.md through the Orchestrator (PlanReviewer)
agent: Orchestrator
---

Review the `PLAN.md` for logical consistency and completeness.

- If there is no `PLAN.md`, stop and report it — no review is performed.
- Delegate to the **PlanReviewer**. It must verify the dependency graph (unique task IDs, known acyclic dependencies), ownership (explicit repository-relative paths, declared shared resources, no overlap among parallel-safe tasks), and validation commands, in addition to completeness and feasibility. If the plan points to tasks in `tasks/`, ensure the relative file paths are correct and review them as part of the plan.
- If the plan is fine, the PlanReviewer leaves a Review Log entry with the status "Approved."
- If there are issues, the critique is written to the `PLAN.md` review log so the Planner can address them.

Scope narrowing (optional):

$ARGUMENTS
