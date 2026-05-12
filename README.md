# Agentic Harness

## Agents

| Agent | Description |
|---|---|
| [🧠 **Planner**](.opencode/agents/Planner.md) | Strategic software architect that interrogates requirements, consults Explorer & Librarian, and produces a structured `PLAN.md` before any code is written. |
| [🧠 **Builder**](.opencode/agents/Builder.md) | Software developer that implements tasks defined in `PLAN.md` one at a time, validates with linters/tests, and triggers the Committer after each unit. |
| [🧠 **Chronicler**](.opencode/agents/Chronicler.md) | Knowledge manager and evolution specialist that writes post-mortems, rescues stalled processes, archives `PLAN.md`, and proposes harness improvements. |
| [🧠 **Dreamer**](.opencode/agents/Dreamer.md) | Metacognitive consolidator that audits `AGENTS.md` and archived plans for redundancies and inconsistencies, then proposes and applies structural improvements after user confirmation. |
| [⚙️ **Reviewer**](.opencode/agents/Reviewer.md) | Senior critic and sole authority to mark tasks `[x]` in `PLAN.md`; reviews both the plan (Mode 1) and the implementation (Mode 2) for correctness, security, and plan compliance. |
| [⚙️ **Committer**](.opencode/agents/Committer.md) | Specialized Git sub-agent that stages and commits changes using Conventional Commits; triggered by the Builder after every successful change. |
| [⚙️ **Explorer**](.opencode/agents/Explorer.md) | Read-only code analyst that maps the existing codebase, identifies entry points and dependencies, and reports precise findings to Planner and Builder. |
| [⚙️ **Librarian**](.opencode/agents/Librarian.md) | Information specialist that fetches external documentation, API references, and best practices from the web and synthesizes them for Planner and Builder. |
| [🧠 **Testing**](.opencode/agents/Testing.md) | Minimal agent used to test and validate the agent harness and its environment. |

- 🧠: Primary agent — can spawn sub-agents
- ⚙️: Sub-agent

### Tool Permissions by Agent

| Agent            | filesystem         | filesystem (readonly) | git | execute processes | search | fetch | context7 |
|------------------|--------------------|-----------------------|-----|-------------------|--------|----------|-------|
| 🧠 **Planner**    | ☑️ (`PLAN.md` only) |                       |     |                   |        |          |       |
| 🧠 **Builder**    | ☑️                  |                       |     | ☑️                 |        |          |       |
| 🧠 **Chronicler** | ☑️                  |                       | ☑️   |                   |        |          |       |
| 🧠 **Dreamer**    | ☑️                  |                       | ☑️   |                   |        |          |       |
| ⚙️ **Reviewer**   |                    | ☑️                     |     |                   |        |          |       |
| ⚙️ **Committer**  |                    | ☑️                     | ☑️   |                   |        |          |       |
| ⚙️ **Explorer**   |                    | ☑️                     |     |                   |        |          |       |
| ⚙️ **Librarian**  |                    |                       |     |                   | ☑️      | ☑️        | ☑️     |
| 🧠 **Testing**    | ☑️                  | ☑️                     | ☑️   | ☑️                 | ☑️      | ☑️        | ☑️     |

**Note: "execute processes" is not implemented right now!**

## Setup

```sh
brew bundle
bin/build-docker-mcp.sh
docker mcp feature enable profiles
docker mcp feature disable dynamic-tools
echo "export DOCKER_MCP_IN_CONTAINER=1" >> ~/.bash_profile
docker mcp catalog pull mcp/docker-mcp-catalog:latest
```

For full setup, profile management, and server configuration see **[docs/mcp/SETUP.md](docs/mcp/SETUP.md)**.

## MCP Reference

- [Servers](docs/mcp/SERVERS.md) — available MCP servers and their sources
- [Tools](docs/mcp/TOOLS.md) — full tool catalogue with signatures and descriptions
- [Profiles](docs/mcp/PROFILES.md) — available profiles created from servers (and their tools)
