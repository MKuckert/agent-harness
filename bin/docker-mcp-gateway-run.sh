#!/usr/bin/env bash

usage() {
  echo "Usage: $(basename "$0") <profile> [<directory>]"
  echo "  <profile>    The profile name (e.g., 'fsrw', 'git', 'full')."
  echo "               Use 'docker mcp profile list' to list all profiles available"
  echo "  <directory>  Full path to an existing working directory (default: current dir)"
  exit 1
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Error: expected 1 or 2 arguments."
  usage
fi

PROFILE="$1"
WORK_PATH="${2:-$PWD}"

if [[ ! -d "$WORK_PATH" ]]; then
  echo "Error: '$WORK_PATH' is not an existing directory."
  usage
fi

case "$PROFILE" in
  fsrw|fsro)
    docker mcp profile config "$PROFILE" --set rust-mcp-filesystem.allowed_directories="$WORK_PATH"
    ;;
  git)
    docker mcp profile config "$PROFILE" --set git.paths="$WORK_PATH"
    ;;
  full)
    docker mcp profile config "$PROFILE" --set rust-mcp-filesystem.allowed_directories="$WORK_PATH"
    docker mcp profile config "$PROFILE" --set git.paths="$WORK_PATH"
    ;;
esac

exec docker mcp gateway run --memory 300Mb --cpus 1 --profile "$PROFILE"
