#!/usr/bin/env bash
#
# Idempotent schema installer for the Annapurna canteen database.
# Run by the db-init service in docker-compose.yml.
#
# Distinguishes three states rather than two:
#   COMPLETE - marker table present, nothing to do
#   EMPTY    - no application objects, safe to install
#   PARTIAL  - objects exist but no marker, meaning an earlier run died
#              part-way. Installing over this yields ORA-00955, so refuse
#              unless RESET=1 is set.
#
# Exits 0 when the schema is present and healthy, non-zero otherwise,
# which is what gates the backend via service_completed_successfully.

set -euo pipefail

: "${APP_USER:?APP_USER is required}"
: "${APP_PASSWORD:?APP_PASSWORD is required}"
: "${DB_SERVICE:=XEPDB1}"
: "${DB_HOST:=database}"
: "${DB_PORT:=1521}"
: "${RESET:=0}"

SQL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONN="${APP_USER}/${APP_PASSWORD}@//${DB_HOST}:${DB_PORT}/${DB_SERVICE}"

find_script() {
  local pattern="$1"
  shopt -s nullglob
  local matches=("${SQL_DIR}"/${pattern})
  shopt -u nullglob

  if [ ${#matches[@]} -eq 0 ]; then
    echo "ERROR: no script matching '${pattern}' in ${SQL_DIR}" >&2
    ls -la "${SQL_DIR}" >&2
    return 1
  fi
  if [ ${#matches[@]} -gt 1 ]; then
    echo "ERROR: multiple scripts match '${pattern}': ${matches[*]}" >&2
    return 1
  fi
  basename "${matches[0]}"
}

# Files are committed uppercase (00-INIT.sql); match case-insensitively.
ENTRY="$(find_script '00-[Ii][Nn][Ii][Tt].sql')"

echo "SQL directory : ${SQL_DIR}"
echo "Entry script  : ${ENTRY}"
echo "Target        : ${APP_USER}@//${DB_HOST}:${DB_PORT}/${DB_SERVICE}"
echo

# Two counts in one round trip: the completion marker, and how many
# application objects exist regardless of completion.
read -r MARKER OBJECTS <<< "$(sqlplus -S "${CONN}" <<'EOSQL' | tr -s ' ' | tail -1
SET HEADING OFF FEEDBACK OFF PAGESIZE 0 LINESIZE 100
SELECT (SELECT COUNT(*) FROM user_tables WHERE table_name = 'INIT_HEALTH_STATUS_TBL')
       || ' ' ||
       (SELECT COUNT(*) FROM user_objects
         WHERE object_name LIKE 'FOO\_%'   ESCAPE '\'
            OR object_name LIKE 'CUST\_%'  ESCAPE '\'
            OR object_name LIKE 'OM\_%'    ESCAPE '\'
            OR object_name LIKE 'BILL\_%'  ESCAPE '\'
            OR object_name LIKE 'AUDIT\_%' ESCAPE '\'
            OR object_name LIKE 'RPT\_%'   ESCAPE '\')
  FROM dual;
EXIT
EOSQL
)"

echo "Marker table  : ${MARKER}"
echo "App objects   : ${OBJECTS}"
echo

if [ "${MARKER}" = "1" ]; then
  echo "Schema already installed. Nothing to do."
  exit 0
fi

if [ "${OBJECTS}" != "0" ]; then
  if [ "${RESET}" = "1" ]; then
    DROP_SCRIPT="$(find_script '99-[Dd][Rr][Oo][Pp].sql')"
    echo "PARTIAL install detected (${OBJECTS} object(s), no marker)."
    echo "RESET=1, so running ${DROP_SCRIPT} first..."
    cd "${SQL_DIR}"
    sqlplus -S "${CONN}" "@${DROP_SCRIPT}"
    echo
  else
    echo "ERROR: partial install detected." >&2
    echo "  ${OBJECTS} application object(s) exist, but the schema was never" >&2
    echo "  marked complete. An earlier run failed part-way through." >&2
    echo >&2
    echo "  Installing over this will fail with ORA-00955. To clear and" >&2
    echo "  reinstall, re-run with RESET=1:" >&2
    echo >&2
    echo "    docker compose run --rm -e RESET=1 --entrypoint bash db-init /sql/install.sh" >&2
    echo >&2
    echo "  Or drop the volume entirely: docker compose down -v" >&2
    exit 1
  fi
fi

echo "Running ${ENTRY}..."
# The orchestrator includes its modules with @@, which resolves relative to
# the calling script's directory, so run from SQL_DIR.
cd "${SQL_DIR}"
sqlplus -S "${CONN}" "@${ENTRY}"