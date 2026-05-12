# MCP Setup Guide

## Prerequisites

Install homebrew dependencies:

```sh
brew bundle
```

## Docker MCP (Model Context Protocol)

### Build the [docker mcp plugin](https://github.com/docker/mcp-gateway)

This makes and installs the `docker mcp` plugin.

```sh
bin/build-docker-mcp.sh
```

Enable the _profiles_ feature:

```sh
docker mcp feature enable profiles
```

You may like to disable dynamic tools, so agents can't add new MCP servers:

```sh
docker mcp feature disable dynamic-tools
```

If you're not running Docker Desktop, set this flag in your `.bash_profile`:

```sh
# Running without Docker Desktop Feature Flags
export DOCKER_MCP_IN_CONTAINER=1
```

Pull the Docker MCP catalog:

```sh
docker mcp catalog pull mcp/docker-mcp-catalog:latest
```

## Profiles

### Create a profile

Creates a new profile named `test`:

```sh
docker mcp profile create --name test
```

### Add servers from Docker Hub (docker mcp catalog)

The default catalog is `catalog://mcp/docker-mcp-catalog` (see https://hub.docker.com/mcp).

Map a Hub URL to a catalog reference:

```
https://hub.docker.com/mcp/server/duckduckgo/overview
                                  `--------´
                                      |
                                  ,--------.
 catalog://mcp/docker-mcp-catalog/duckduckgo
```

Add a server:

```sh
docker mcp profile server add test --server catalog://mcp/docker-mcp-catalog/duckduckgo
```

### Add servers from a local file spec

Add arbitrary Docker containers using a [local file spec](https://github.com/docker/mcp-gateway/blob/main/docs/server-entry-spec.md).

Example spec for `sonirico/mcp-shell`:

```yaml
name: mcp-shell
title: Shell
type: server
image: sonirico/mcp-shell@sha256:11eb9e31ca353362d3bb5b3ce850ccd8e40d708228e20690fbc7474003062261
description: Provides a shell executable
```

Add the server:

```sh
docker mcp profile server add test --server file://path/to/mcp-shell.yaml
```

### Import / Export profiles

Export a named profile to YAML (`.json` is also supported):

```sh
docker mcp profile export $PROFILE export-for-$PROFILE.yaml
```

Import a profile. **Warning: an existing profile with the same name is completely overwritten.**

```sh
docker mcp profile import export-for-$PROFILE.yaml
```

## Running the Gateway

Using profile `$PROFILE`.

### STDIO

```sh
docker mcp gateway run \
    --profile $PROFILE \
    --memory 300Mb \
    --cpus 1
```

### HTTP Streaming

```sh
docker mcp gateway run \
    --port 8080 --transport streaming \
    --profile $PROFILE \
    --memory 300Mb \
    --cpus 1
```

## Adding to clients

One have to register the mcp server in the AI client to access it. It's tempting to use the `docker mcp client connect` command to simplify the registration but this tool is laughable at best. It overwrites previous registrations with other profiles. For opencode it doesn't handle `.jsonc` configs correctly but places its own file beside, resulting in broken configs.

Do yourself a favor and configure your client on your own - it's not that big of a deal.

You have to either
- add calls to the `gateway run` command starting the profile in STDIO mode, or
- add the localhost URI to a (manually started) gateway in http streaming mode
You decide.

You'd also like to pass `--memory` and `--cpus` flags to limit the resources available to containers started.

Than add your configuration to your client, e.g. for opencode, running the gateway with `full` profile in STDIO mode:

```json
  "mcp": {
    "full": {
      "type": "local",
      "enabled": true,
      "command": ["docker", "mcp", "gateway", "run", "--memory", "300Mb", "--cpus", "1", "--profile", "full"],
    },
  },
```

You can use the `bin/docker-mcp-gateway-run.sh` wrapper to simplify the command:

```json
  "mcp": {
    "full": {
      "type": "local",
      "enabled": true,
      "command": ["bin/docker-mcp-gateway-run.sh", "full"],
    },
  },
```

Or add the gateway running with `full` profile in http streaming mode on port 8080:

```json
  "mcp": {
    "full": {
      "type": "remote",
      "enabled": true,
      "url": "http://localhost:8080/mcp",
    },
  },
```

### Adding all profiles

You have to add multiple configs to your client if you're using [all profiles](PROFILES.md), e.g. when using opencode:

```json
  "mcp": {
    "fsrw": {
      "type": "local",
      "enabled": true,
      "command": ["bin/docker-mcp-gateway-run.sh", "fsrw"],
    },
    "fsro": {
      "type": "local",
      "enabled": true,
      "command": ["bin/docker-mcp-gateway-run.sh", "fsro"],
    },
    "git": {
      "type": "local",
      "enabled": true,
      "command": ["bin/docker-mcp-gateway-run.sh", "git"],
    },
    "web": {
      "type": "local",
      "enabled": true,
      "command": ["bin/docker-mcp-gateway-run.sh", "web"],
    },
  },
```

Give your agent permission to use the tools:

(in `.opencode/agents/Testing.md`)

```md
---
description: "You are an agent used to test the agent harness"
mode: primary
permission:
  read: allow
  fsrw_*: allow
  git_*: allow
  web_*: allow
---
### System Prompt: The Testing Agent

You are here to help me test my agent harness and environment.
```

```sh
opencode --agent Testing --prompt "Which tools are available to you?"
```

```
I have access to the following tools:

File System Operations (fsrw_*, read)
*   fsrw_create_directory: Create directories.
*   fsrw_directory_tree: View directory structure.
*   fsrw_edit_file: Edit text files.
*   fsrw_get_file_info: Retrieve metadata about files/directories.
*   fsrw_head_file: Read the start of a file.
*   fsrw_list_directory: List directory contents.
*   fsrw_move_file: Move or rename files/directories.
*   fsrw_read_file_lines: Read specific lines from a file.
*   fsrw_read_multiple_text_files: Read multiple files at once.
*   fsrw_read_text_file: Read a complete text file.
*   fsrw_search_files: Find files by pattern/size.
*   fsrw_search_files_content: Search content within files.
*   fsrw_tail_file: Read the end of a file.
*   fsrw_write_file: Create or overwrite files.
*   read: General filesystem read tool (file/directory).

Git Operations (git_*)
*   git_git_add: Stage file changes.
*   git_git_checkout: Switch branches.
*   git_git_commit: Create commits.
*   git_git_diff: Compare branches/commits.
*   git_git_diff_staged: Show staged changes.
*   git_git_diff_unstaged: Show unstaged changes.
*   git_git_log: View commit history.
*   git_git_show: View commit details.
*   git_git_status: Check working tree status.

Task Management (task)
*   task: Launch autonomous subagents (Committer, Explorer, Librarian, Reviewer).

Web/Internet Access (web_*)
*   web_fetch: Fetch content from URLs.
*   web_get-library-docs: Retrieve library documentation.
*   web_resolve-library-id: Resolve library names to IDs.
*   web_search: Perform web searches via DuckDuckGo.

▣  Testing · Gemini 3.1 Flash Lite Preview · 4.5s
```

## MCP CLI Tool

[`mcp`](https://github.com/f/mcptools) is a command-line interface for interacting with MCP servers. It lets you discover and call tools, list resources, and interact with MCP-compatible services.

Test tools provided by your gateway:

```sh
mcp tools docker mcp gateway run --profile $PROFILE
```

Open an interactive shell:

```sh
mcp shell docker mcp gateway …
```

Open the web UI:

```sh
mcp web docker mcp gateway …
# open the displayed URI in your browser
```
