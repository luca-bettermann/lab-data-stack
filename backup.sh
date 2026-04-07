#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

require_env

source .env

TIMESTAMP="$(date +%Y%m%d-%H%M)"
SQL_FILE="backup-${TIMESTAMP}.sql"
ZIP_FILE="backup-${TIMESTAMP}.zip"

echo "Dumping all PostgreSQL databases to $SQL_FILE ..."

if ! pg_backup_dump "${PROJECT_NAME:-lab-data-stack}" "$POSTGRES_USER" "$SQL_FILE"; then
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
echo "  Contains: $SQL_FILE + .env (credentials)"
echo ""
echo "Store this file somewhere safe — it is NOT backed up by git."
echo ""
