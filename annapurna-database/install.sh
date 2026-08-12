#!/usr/bin/env bash
#
# Idempotent schema installer for the Annapurna canteen database.
# Run by the db-init service in docker-compose.yml.
#
# Exits 0 when the schema is present and healthy, non-zero otherwise,
# which is what gates the backend via service_completed_successfully.

set -euo pipefail

: "${APP_USER:?APP_USER is required}"
: "${APP_PASSWORD:?APP_PASSWORD is required}"
: "${DB_SERVICE:=XEPDB1}"
: "${DB_HOST:=database}"
: "${DB_PORT:=1521}"

CONN="${APP_USER}/${APP_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SERVICE}"

echo "Checking whether the schema is already installed..."

INSTALLED=$(sqlplus -S "${CONN}" <<'EOSQL'
SET HEADING OFF FEEDBACK OFF PAGESIZE 0
SELECT COUNT(*) FROM user_tables WHERE table_name = 'INIT_HEALTH_STATUS_TBL';
EXIT
EOSQL
)

if [ "$(echo "${INSTALLED}" | tr -d '[:space:]')" = "1" ]; then
  echo "Schema already present. Skipping install."
  exit 0
fi

echo "Running 00-init.sql..."
cd /sql
sqlplus -S "${CONN}" @00-init.sql