# TODO

- Deviation: `Planner` agent should only be able to write plans (`PLAN.md`) but can access the full filesystem right now (`fsrw_*: allow`)
- Missing: `Builder` agent should be able to execute (some) shell commands. This is not implemented right now and not that simple.
  What about raw shell access? When in doubt, do I want to lock the entire compiler in a container? What might not work for some tools, e.g. xcode? Or cross-compiling forced? Do I use an MCP server directly on the host with (hopefully implemented cleanly) allow list for possible commands or an indirection in between? I am currently missing a good idea here.
