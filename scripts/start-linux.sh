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

if grep -q 'shizr/medicine-bigdata:\(mysql-1\.0\.0\|backend-1\.[023]\.0\|frontend-1\.[0-3]\.0\)' .env; then
  sed -i.bak \
    -e 's#shizr/medicine-bigdata:mysql-1\.0\.0#shizr/medicine-bigdata:mysql-1.1.0#g' \
    -e 's#shizr/medicine-bigdata:backend-1\.[023]\.0#shizr/medicine-bigdata:backend-1.4.0#g' \
    -e 's#shizr/medicine-bigdata:frontend-1\.[0-3]\.0#shizr/medicine-bigdata:frontend-1.4.0#g' \
    .env
  rm -f .env.bak
  echo "Updated public application images to version 1.4.0."
fi

if [ "${1:-}" = "--full" ]; then
  docker compose --profile bigdata pull
  docker compose --profile bigdata up -d --no-build
else
  docker compose pull
  docker compose up -d --no-build
fi

echo "Applying safe database migrations..."
docker compose exec -T mysql sh -c 'mysql --default-character-set=utf8mb4 -uroot -p"$MYSQL_ROOT_PASSWORD" his_system < /migrations/001_ensure_patient_cards.sql'

echo ""
echo "Started. Open: http://localhost"
echo "Username: admin"
echo "Password: 123456"
