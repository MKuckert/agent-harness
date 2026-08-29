# Agentic Harness

## Agents

| Agent                                                                      | Description                                                                                                                                                 |
| -------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [🧠 **Orchestrator**](.opencode/agents/Orchestrator.md)                     | Single coordinator of the plan → implement → review → commit lifecycle; routes all lifecycle commands and enforces batching, retry, and concurrency rules.    |
| [⚙️ **Planner**](.opencode/agents/Planner.md)                              | Strategic software architect (hidden subagent) that interrogates requirements, consults Explorer & Librarian, and produces a structured `PLAN.md`.           |
| [⚙️ **Builder**](.opencode/agents/Builder.md)                              | Software developer (hidden subagent) that implements only the Orchestrator-supplied task scope; cannot edit `PLAN.md` or commit except during finalization.    |
| [🧠 **Buddy**](.opencode/agents/Buddy.md)                                  | Default general-purpose technical assistant; delegates lifecycle intent to the Orchestrator, retains general assistance.                                    |
| [⚙️ **Plan Reviewer**](.opencode/agents/PlanReviewer.md)                   | Reviews the Planner's work, including the dependency graph (IDs, cycles, ownership, overlap, validation); sole authority to approve `PLAN.md`.               |
| [⚙️ **Code Reviewer**](.opencode/agents/CodeReviewer.md)                   | Reviews exactly one task-scope for correctness, security, and plan compliance; sole authority to mark tasks `[x]` in `PLAN.md`.                            |
| [⚙️ **Committer**](.opencode/agents/Committer.md)                          | Git sub-agent that stages only explicitly supplied paths plus `PLAN.md`; aborts on ambiguous scope; triggered only during Orchestrator-authorized finalization. |
| [⚙️ **Explorer**](.opencode/agents/Explorer.md)                            | Read-only code analyst that maps the existing codebase, identifies entry points and dependencies, and reports precise findings.                            |
| [⚙️ **Librarian**](.opencode/agents/Librarian.md)                          | Information specialist that fetches external documentation and writes durable research artifacts under `research/results/` per the Research Artifact Contract.   |
| [🧠 **Documentation Engineer**](.opencode/agents/DocumentationEngineer.md) | Specialized agent for writing, organizing, and maintaining technical documentation and guides.                                                              |
| [⚙️ **Testing**](.opencode/agents/Testing.md)                              | Non-editing subagent that runs plan-approved validation commands for finished tasks; never modifies source, config, `PLAN.md`, or Git state.                 |

- 🧠: Primary agent — can spawn sub-agents
- ⚙️: Sub-agent

### Tool Permissions by Agent

| Agent                        | read | edit | grep | glob | bash    | task | web | skill |
| ---------------------------- | ---- | ---- | ---- | ---- | ------- | ---- | --- | ----- |
| 🧠 **Orchestrator**          | ✓    | ✓\*  | ✓    | ✓    |         | ✓\*\*\*\* |  | ✓     |
| ⚙️ **Planner**               |      | ✓\*  |      |      |         | ✓\*\*\*\* |  | ✓     |
| ⚙️ **Builder**               | ✓    | ✓\*\* | ✓    | ✓    | ✓\*\*   | ✓\*\*\*\* |  | ✓     |
| 🧠 **Buddy**                 | ✓    | ✓    | ✓    | ✓    | ✓\*\*   | ✓\*\*\*\* |  | ✓     |
| ⚙️ **PlanReviewer**          | ✓    | ✓\*  | ✓    | ✓    |         | ✓\*\*\*\* |  | ✓     |
| ⚙️ **CodeReviewer**          | ✓    | ✓\*  | ✓    | ✓    |         | ✓\*\*\*\* |  | ✓     |
| ⚙️ **Committer**             | ✓    |      | ✓    | ✓    | ✓\*\*\* |      |     | ✓     |
| ⚙️ **Explorer**              | ✓    | ✓†   | ✓    | ✓    |         |      |     | ✓     |
| ⚙️ **Librarian**             |      | ✓‡   |      |      |         |      | ✓   | ✓     |
| 🧠 **DocumentationEngineer** | ✓    | ✓    | ✓    | ✓    |         |      |     |       |
| ⚙️ **Testing**               | ✓    |      | ✓    | ✓    | ✓\*\*\*\*\* |  |  |       |

**Legend:**

- `*` = PLAN.md only
- `**` = Selective (git commands denied; `PLAN.md` denied for the Builder)
- `***` = Git commands only (status, add, commit)
- `****` = Deny-by-default; only the mapped task targets below are allowed
- `*****` = `ask` (user approval per command)
- `†` = PROJECT_MAP.md only
- `‡` = `research/results/**` only

### Task Target Mapping (deny-by-default)

| Agent          | Allowed task targets |
| -------------- | -------------------- |
| Buddy          | Orchestrator, Explorer, Librarian |
| Orchestrator   | Planner, Builder, Testing, PlanReviewer, CodeReviewer, Explorer, Librarian (never Committer) |
| Planner        | Explorer, Librarian, PlanReviewer |
| Builder        | Committer (during Orchestrator-authorized finalization only) |
| PlanReviewer   | Explorer, Librarian |
| CodeReviewer   | Explorer, Librarian |
| Explorer / Librarian / Testing / Committer | — (leaves) |

Built-in `build`, `plan`, `general`, and `explore` agents remain disabled so lifecycle work cannot bypass the Orchestrator. `subagent_depth` is `5`.

## Lifecycle

All lifecycle commands route through the **Orchestrator**:

| Command | Effect |
| ------- | ------ |
| `/plan` | Foreground planning via Planner (user questions allowed); asks before replacing a nonempty `PLAN.md` |
| `/continue_implementation` | Dispatches at most two dependency-ready, parallel-safe, path-disjoint Builders; batch barrier; sequential finalization (Testing → CodeReviewer ≤3 rounds → `[x]` → Committer). Replaces `/implement_next_task` |
| `/review_plan` | PlanReviewer pass over `PLAN.md` including the dependency graph |
| `/review_code` | CodeReviewer pass over one identifiable task/change scope — no vague general review |
| `/research` | Orchestrator → Librarian directly; one durable artifact per run under `research/results/` per the Research Artifact Contract (max 4 distinct topics in parallel); no skill generation |
| `/archive_plan` | Unchanged, Buddy-owned |

**Rules and retry policy:**

- **Cooperative parallelism:** max 2 Builders / 4 Librarians. Claims are prompt/session coordinated — **not atomic, not safe across independent OpenCode processes**, and documented as such.
- **Batch barrier:** no Builder edits `PLAN.md`, invokes review, or commits while a batch is active; the Orchestrator never mutates the plan while a batch runs. A Builder that exhausts recovery aborts review/commit for the whole batch.
- **Retries:** one same-session resume for any technical Task failure (timeout, API/tool error, step-limit/incomplete result, unavailable session); only a Builder gets one further fresh session that must continue the partial work. Review critique, test failure, user rejection, and invalid state are not technical failures.
- **Preconditions:** missing/malformed/unapproved/completed/dependency-blocked plans stop deterministically without retry or child dispatch.
- **Research artifacts:** the Librarian may write only under `research/results/` (workspace-relative), per the Research Artifact Contract ([docs/research-artifact-contract.md](docs/research-artifact-contract.md)); each consuming workspace provisions its own `research/results/` directory. Research verification remains issue #85.
- **Sync:** authoritative changes in this repo are propagated to parent projects via `bin/harness-sync.sh`; restart OpenCode after config changes.

### Validation

- `bin/check-harness.sh` — dependency-free static checks (agent modes, task mappings, built-in disablement, depth, command routing, plan fields, Librarian confinement).
- **Manual smoke checklist** (record pass/fail with brief evidence): Planner question flow; one and two Builder execution; overlap rejection; missing background support; same-session retry and Builder fresh continuation; failed-batch no-review/no-commit; validation/review correction; scoped sequential commits; up to four distinct Librarians; Buddy natural-language delegation.

## Setup

```sh
brew bundle
bin/build-docker-mcp.sh
docker mcp feature enable profiles
docker mcp feature disable dynamic-tools
echo "export DOCKER_MCP_IN_CONTAINER=1" >> ~/.bash_profile
docker mcp catalog pull mcp/docker-mcp-catalog:latest
profiles/build.sh

# now configure your AI client to include the following STDIO MCPs
# bin/docker-mcp-gateway-run.sh fsrw
# bin/docker-mcp-gateway-run.sh fsro
# bin/docker-mcp-gateway-run.sh git
# bin/docker-mcp-gateway-run.sh web
```

For full setup, profile management, and server configuration see **[docs/mcp/SETUP.md](docs/mcp/SETUP.md)**.

## Reference

- [Profiles](docs/mcp/PROFILES.md) — available profiles created from servers (and their tools)
- [Servers](docs/mcp/SERVERS.md) — available MCP servers and their sources
- [Tools](docs/mcp/TOOLS.md) — full tool catalogue with signatures and descriptions

## License

- The [`grill-me`](.opencode/skills/grill-me/SKILL.md) skill is from [Matt Pocock](https://github.com/mattpocock/skills/blob/main/skills/productivity/grilling/SKILL.md) and licensed under MIT
- The [`Documentation Engineer`](.opencode/agents/DocumentationEngineer.md) agent is from [Awesome Claude Code Subagents](https://github.com/VoltAgent/awesome-claude-code-subagents/) and licensed under MIT
