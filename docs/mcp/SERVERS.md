# MCP Servers

All servers run via the Docker MCP gateway.

See [SETUP.md](SETUP.md) for installation and profile configuration.

## [context7](https://github.com/upstash/context7)

Up-to-date library documentation lookups.  

Uses the docker-built [mcp server](https://hub.docker.com/mcp/server/context7/overview).

## [fetch](https://github.com/modelcontextprotocol/servers/tree/main/src/fetch)

HTTP fetching with Markdown extraction.  

Uses the docker-built [mcp server](https://hub.docker.com/mcp/server/fetch/overview).

## [git](https://github.com/modelcontextprotocol/servers/tree/main/src/git)

Git repository operations.  

Uses the docker-built [mcp server](https://hub.docker.com/mcp/server/git/overview).

## [filesystem](https://github.com/rust-mcp-stack/rust-mcp-filesystem)

Sandboxed filesystem read/write access.  

Uses the docker-built [mcp server](https://hub.docker.com/mcp/server/rust-mcp-filesystem/overview).

## [shell](https://github.com/sonirico/mcp-shell)

Shell command execution.

Installed via [local file spec](https://github.com/docker/mcp-gateway/blob/main/docs/server-entry-spec.md), leveraging the [official docker container](https://hub.docker.com/r/sonirico/mcp-shell).

## [search](https://github.com/nickclyde/duckduckgo-mcp-server)

Web search via DuckDuckGo.  

Uses the docker-built [mcp server](https://hub.docker.com/mcp/server/duckduckgo/overview).
