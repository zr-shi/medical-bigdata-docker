#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker was not found. Install Docker Engine and Docker Compose first."
  exit 1
fi

if [ ! -f .env ]; then
  cp .env.example .env
  echo "Created .env. Change its passwords before an Internet deployment."
fi

if [ "${1:-}" = "--full" ]; then
  docker compose --profile bigdata pull
  docker compose --profile bigdata up -d --no-build
else
  docker compose pull
  docker compose up -d --no-build
fi

echo ""
echo "Started. Open: http://localhost"
echo "Username: admin"
echo "Password: 123456"
