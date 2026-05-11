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
