#!/usr/bin/env bash

usage() {
  echo "Usage: $(basename "$0") <directory>"
  echo "  <directory>  Full path to an existing directory to allow filesystem access"
  exit 1
}

PROFILE=full
PORT=8080

if [[ $# -ne 1 ]]; then
  echo "Error: exactly one argument required." >&2
  usage
fi

if [[ ! -d "$1" ]]; then
  echo "Error: '$1' is not an existing directory." >&2
  usage
fi

WORK_PATH="$1"

docker mcp profile config $PROFILE --set git.paths="$WORK_PATH"
docker mcp profile config $PROFILE --set rust-mcp-filesystem.allowed_directories="$WORK_PATH"
docker mcp gateway run --memory 300Mb --port $PORT --transport streaming --profile $PROFILE
