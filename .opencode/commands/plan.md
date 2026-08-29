---
description: Plans a feature through the Orchestrator (foreground Planner with user questions)
agent: Orchestrator
---

Plan the following feature.

1. If a nonempty `PLAN.md` already exists, ask me before replacing it; on cancellation keep the existing plan.
2. Delegate to the **Planner** in the foreground. It may ask me questions directly while running — wait for those answers.
3. When the plan is drafted and approved by the PlanReviewer, summarize the plan and the dependency graph briefly.

The feature to plan:

$ARGUMENTS
