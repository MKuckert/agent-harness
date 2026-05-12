#!/usr/bin/env bash
exec docker mcp gateway run --memory 300Mb --cpus 1 --profile $@
