# Agentic Harness

## Prepare environment

Install homebrew dependencies:

```
brew bundle
```

## Build the mcp container

_Assumes colima and `nerdctl` are installed. Use `docker` otherwise._

```
nerdctl compose build
```

## Provided mcp containers:

Don't run those commands on your own as the process listens for STDIN commands. You'd likely not able to cancel that process through `CTRL+C`.

They follow this structure:

```
nerdctl run --rm -i containered-mcps-$NAME $COMMAND
         ^                             ^       ^
         |                             |       |
         |                             |       `- command in the container to run.
         |                             |          Depends on your npx/uvx call.
         |                             |
         |                             `- service name as defined in the compose file
         |
         `- runs the pre-build container

```

### Context7

```
nerdctl compose run --rm context7
```
