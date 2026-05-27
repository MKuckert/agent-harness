# Profiles

The following profiles with corresponding tools are available.

- `fsrw`: Writable filesystem
- `fsro`: Readonly filesystem
- `git`: Git repository handling
<!-- - `shell`: Process execution-->
- `web`: Searching and fetching web content, e.g. from context7
- `full`: Includes all tools, for simpler agent systems or just for testing purposes

Run `profiles/build.sh` to create those profiles.

You can run those profiles afterwards using `docker mcp gateway run`:

```sh
# STDIO
docker mcp gateway run --profile $PROFILE

# HTTP Streaming
docker mcp gateway run --port 8080 --transport streaming --profile $PROFILE
```

See [Setup](SETUP.md) for more examples.

## Configuration

Sadly (or: for safeties sake) one has to configure the containers with filesystem access to specify the working directory. You have to call `docker mcp profile config` with proper values before starting and using your gateway.

Relevant configs:

| profile | config             |
| ------- | ------------------ |
| fsrw    | `filesystem.paths` |
| fsro    | `filesystem.paths` |
| full    | `filesystem.paths` |
| git     | `git.paths`        |
| full    | `git.paths`        |

You can use `bin/docker-mcp-gateway-run.sh $PROFILE` to set this configs when starting the gateway.
