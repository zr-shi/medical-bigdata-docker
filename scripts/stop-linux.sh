#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."

if [ "${1:-}" = "--delete-data" ]; then
  docker compose --profile bigdata down --volumes
else
  docker compose --profile bigdata down
fi

