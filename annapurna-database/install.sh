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

SQL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONN="${APP_USER}/${APP_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SERVICE}"

# Fail with a readable message rather than letting SQL*Plus report SP2-0310.
MODULES=(00-init.sql 01-FOO.sql 02-CUST.sql 03-OM.sql 04-BILL.sql 05-AUDIT.sql 06-RPT.sql)
MISSING=()
for f in "${MODULES[@]}"; do
  [ -f "${SQL_DIR}/${f}" ] || MISSING+=("${f}")
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "ERROR: missing SQL file(s) in ${SQL_DIR}: ${MISSING[*]}" >&2
  echo "Contents of ${SQL_DIR}:" >&2
  ls -la "${SQL_DIR}" >&2
  echo >&2
  echo "Check that docker-compose.yml mounts the directory holding these files" >&2
  echo "at /sql (volumes: - ./annapurna-database:/sql:ro)." >&2
  exit 1
fi

echo "SQL directory : ${SQL_DIR}"
echo "Target        : ${APP_USER}@//${DB_HOST}:${DB_PORT}/${DB_SERVICE}"

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
# 00-init.sql uses @@ for its module includes, which resolves relative to the
# calling script, so run from SQL_DIR rather than passing an absolute path.
cd "${SQL_DIR}"
sqlplus -S "${CONN}" @00-init.sql