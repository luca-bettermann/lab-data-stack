#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

NO_DATA=false
for arg in "$@"; do
  case "$arg" in
    --no-data) NO_DATA=true ;;
    -h|--help)
      echo "Usage: ./backup.sh [--no-data]"
      echo ""
      echo "  --no-data   Skip row data in NocoDB user tables."
      echo "              Keeps table structure, NocoDB metadata,"
      echo "              and the full Superset DB (dashboards)."
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg"
      echo "Usage: ./backup.sh [--no-data]"
      exit 1
      ;;
  esac
done

require_env

source .env

TIMESTAMP="$(date +%Y%m%d-%H%M)"
if [ "$NO_DATA" = "true" ]; then
  PREFIX="backup-no-data"
else
  PREFIX="backup"
fi
SQL_FILE="${PREFIX}-${TIMESTAMP}.sql"
ZIP_FILE="${PREFIX}-${TIMESTAMP}.zip"

if [ "$NO_DATA" = "true" ]; then
  echo "Dumping PostgreSQL structure + dashboards (no user row data) to $SQL_FILE ..."
  DUMP_FN=pg_backup_dump_no_data
else
  echo "Dumping all PostgreSQL databases to $SQL_FILE ..."
  DUMP_FN=pg_backup_dump
fi

if ! "$DUMP_FN" "${PROJECT_NAME:-lab-data-stack}" "$POSTGRES_USER" "$SQL_FILE"; then
  echo ""
  echo "Backup failed. Is the stack running? Try: docker compose ps"
  echo ""
  rm -f "$SQL_FILE"
  exit 1
fi

echo "Zipping dump + credentials into $ZIP_FILE ..."
zip -j "$ZIP_FILE" "$SQL_FILE" .env
rm -f "$SQL_FILE"

SIZE=$(du -sh "$ZIP_FILE" | cut -f1)

echo ""
echo "Backup complete: $ZIP_FILE ($SIZE)"
if [ "$NO_DATA" = "true" ]; then
  echo "  Contains: $SQL_FILE (structure + dashboards, no row data) + .env"
else
  echo "  Contains: $SQL_FILE + .env (credentials)"
fi
echo ""
echo "Store this file somewhere safe — it is NOT backed up by git."
echo ""
