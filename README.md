# Architecture Specification: Agentic Harness

## 1. Core Philosophy
Maximum isolation through **Git worktrees** and **Docker-based MCP servers**. The process is plan-driven and strictly culminates in human intervention (via a Pull Request). The system's evolution is a collaborative process between the AI Chronicler and the human operator.

## 2. Agent Roles (Summary)
* **Planner (primary, cloud):** Creates the `PLAN.md` file and conducts the interrogator dialogue.
* **Builder (primary, cloud):** Implements code within the isolated worktree.
* **Reviewer (sub, cloud):** Evaluates the plan and code against acceptance criteria.
* **Explorer/Librarian (sub, local):** Provides context from the local codebase and the web.
* **Committer (sub, local):** Generates atomic commits in the feature branch.
* **Chronicler (primary, local):** Curates knowledge and refines system prompts.

## 3. The Refined Workflow

### Phase A: Setup & Strategy (The Origin)
1. **Worktree Initialization:** As the very first step, the harness creates a new **Git worktree** in a separate directory. The branch follows the naming convention `feature/$name`.
2. **Interrogation:** The Planner clarifies the details. The process only advances once the requirements are finalized in the `PLAN.md`.
3. **Plan Review:** The Reviewer validates the draft.

### Phase B: Implementation
1. **Task Execution:** The Builder works through the tasks outlined in the `PLAN.md`.
2. **Continuous Commit:** The Committer immediately saves all progress to the branch.
3. **Local Testing:** All tests are executed within the Builder MCP's Docker container.

### Phase C: Review & Circuit Breaker
1. **AI Review:** The Reviewer verifies the execution. If errors are found, a correction loop is triggered (maximum of 3 iterations).
2. **Stalemate Halt:** If all attempts are exhausted, the process is aborted. A human inspects the worktree and decides how to proceed.

### Phase D: Human Approval & Evolution
1. **Pull Request:** Following the AI execution, a **Pull Request** is generated. Final integration into the `main` branch only occurs after a manual review by a human.
2. **Interactive Chronicle:** The Chronicler drafts the "Lessons Learned" and proposes adjustments to the system prompts.
    * **Human Input:** You supplement or correct the Chronicler's findings.
    * **Final Commit:** The Chronicler records the finalized insights in the `AGENTS.md` and the knowledge archive.
3. **Cleanup:** The worktree is deleted upon a successful merge.

## 4. Structure of PLAN.md

| Section | Purpose | Authority |
|---|---|---|
| **Checklist** | Defined technical framework conditions | Planner |
| **Step-by-Step** | Granular task list for the Builder | Planner |
| **Progress** | Status `[ ]`, `[/]`, `[x]` | Reviewer only |
| **Review Log** | Documentation of rejected implementations | Reviewer |
