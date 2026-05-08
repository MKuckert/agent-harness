# Agentic Harness

## Prepare environment

Install homebrew dependencies:

```sh
brew bundle
```

## Model Context Protocol (MCP)

### Build the [docker mcp plugin](https://github.com/docker/mcp-gateway)

This makes and installs the `docker mcp` plugin.

```sh
bin/build-docker-mcp.sh
```

You have to enable the _profiles_ feature to use this harness.

```sh
docker mcp feature enable profiles
```

You may like to disable dynamic tools, so the agents can`t add new mcp servers:

```sh
docker mcp feature disable dynamic-tools
```

You'd also like to set the following flag in your `.bash_profile` if you're not running Docker Desktop:

```sh
# Running without Docker Desktop Feature Flags
export DOCKER_MCP_IN_CONTAINER=1
```

Pull the Docker MCP catalog
```sh
docker mcp catalog pull mcp/docker-mcp-catalog:latest
```

### Run the gateway

Using profile `$PROFILE`.

#### STDIO

```sh
docker mcp gateway run \
    --profile $PROFILE \
    --memory 300Mb \
    --cpus 1
```

#### HTTP Streaming

```sh
docker mcp gateway run \
    --port 8080 --transport streaming \
    --profile $PROFILE \
    --memory 300Mb \
    --cpus 1
```

### MCP tool

`mcp` is a command line interface for interacting with MCP servers.

It allows you to discover and call tools, list resources, and interact with MCP-compatible services.

You can use it to test tools provided by your mcp gateway:

```sh
mcp tools docker mcp gateway run --profile $PROFILE
```

There's also a shell to interact with your gateway:

```sh
mcp shell docker mcp gateway …
```

Or a web interface, if you're more into GUIs:

```sh
mcp web docker mcp gateway …
# open the displayed URI in your browser
```
