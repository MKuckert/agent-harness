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
