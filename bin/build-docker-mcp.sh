#!/usr/bin/env bash

cd ~/private/dev

if [ ! -d mcp-gateway ]; then
  git clone "git@github.com:docker/mcp-gateway.git"
  cd mcp-gateway
else
  cd mcp-gateway
  git pull --ff
fi

echo "Building docker-mcp $(git log --pretty=tformat:"%H" -1)"

make docker-mcp

echo "Built and installed 'docker mcp'"
