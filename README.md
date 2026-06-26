# Agentic Harness

## Agents

| Agent                                                                      | Description                                                                                                                                                 |
| -------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [🧠 **Planner**](.opencode/agents/Planner.md)                              | Strategic software architect that interrogates requirements, consults Explorer & Librarian, and produces a structured `PLAN.md` before any code is written. |
| [🧠 **Builder**](.opencode/agents/Builder.md)                              | Software developer that implements tasks defined in `PLAN.md` one at a time, validates with linters/tests, and triggers the Committer after each unit.      |
| [🧠 **Buddy**](.opencode/agents/Buddy.md)                                  | Technical assistant for coding, debugging, and development tasks; provides code snippets, explanations, and pragmatic guidance on demand.                   |
| [⚙️ **Plan Reviewer**](.opencode/agents/PlanReviewer.md)                   | Reviews the Planner's work for completeness, feasibility, and architectural soundness; sole authority to approve `PLAN.md` before Builder starts.           |
| [⚙️ **Code Reviewer**](.opencode/agents/CodeReviewer.md)                   | Reviews the Builder's implementation for correctness, security, and plan compliance; sole authority to mark tasks `[x]` in `PLAN.md`.                       |
| [⚙️ **Committer**](.opencode/agents/Committer.md)                          | Specialized Git sub-agent that stages and commits changes using Conventional Commits; triggered by the Builder after every successful change.               |
| [⚙️ **Explorer**](.opencode/agents/Explorer.md)                            | Read-only code analyst that maps the existing codebase, identifies entry points and dependencies, and reports precise findings to Planner and Builder.      |
| [⚙️ **Librarian**](.opencode/agents/Librarian.md)                          | Information specialist that fetches external documentation, API references, and best practices from the web and synthesizes them for Planner and Builder.   |
| [🧠 **Documentation Engineer**](.opencode/agents/DocumentationEngineer.md) | Specialized agent for writing, organizing, and maintaining technical documentation and guides.                                                              |
| [🧠 **Testing**](.opencode/agents/Testing.md)                              | Minimal agent used to test and validate the agent harness and its environment.                                                                              |

- 🧠: Primary agent — can spawn sub-agents
- ⚙️: Sub-agent

### Tool Permissions by Agent

| Agent                        | read | edit | grep | glob | bash    | task | web | skill |
| ---------------------------- | ---- | ---- | ---- | ---- | ------- | ---- | --- | ----- |
| 🧠 **Planner**               |      | ✓\*  |      |      |         | ✓    |     | ✓     |
| 🧠 **Builder**               | ✓    | ✓    | ✓    | ✓    | ✓\*\*   | ✓    |     | ✓     |
| 🧠 **Buddy**                 | ✓    | ✓    | ✓    | ✓    | ✓\*\*   | ✓    |     | ✓     |
| ⚙️ **PlanReviewer**          | ✓    | ✓\*  | ✓    | ✓    |         | ✓    |     | ✓     |
| ⚙️ **CodeReviewer**          | ✓    | ✓\*  | ✓    | ✓    |         | ✓    |     | ✓     |
| ⚙️ **Committer**             | ✓    |      | ✓    | ✓    | ✓\*\*\* |      |     | ✓     |
| ⚙️ **Explorer**              | ✓    | ✓†   | ✓    | ✓    |         |      |     | ✓     |
| ⚙️ **Librarian**             |      |      |      |      |         |      | ✓   | ✓     |
| 🧠 **DocumentationEngineer** | ✓    | ✓    | ✓    | ✓    |         | ✓    |     | ✓     |
| 🧠 **Testing**               | ✓    | ✓    | ✓    | ✓    | ✓       | ✓    | ✓   | ✓     |

**Legend:**

- `*` = PLAN.md only
- `**` = Selective (git commands denied)
- `***` = Git commands only (status, add, commit)
- `†` = PROJECT_MAP.md only

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

- The [`grill-me`](.opencode/skills/grill-me/SKILL.md) skill is from [Matt Pocock](https://github.com/mattpocock/skills/blob/main/skills/productivity/grill-me/SKILL.md) and licensed under MIT
- The [`Documentation Engineer`](.opencode/agents/DocumentationEngineer.md) agent is from [Awesome Claude Code Subagents](https://github.com/VoltAgent/awesome-claude-code-subagents/) and licensed under MIT
