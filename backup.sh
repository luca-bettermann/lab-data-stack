#!/bin/bash

if [ ! -f .env ]; then
  echo ""
  echo "❌ No .env file found."
  echo "   Run this script from the lab-data-stack directory where .env lives."
  echo ""
  exit 1
fi

source .env

TIMESTAMP="$(date +%Y%m%d-%H%M)"
SQL_FILE="backup-${TIMESTAMP}.sql"
ZIP_FILE="backup-${TIMESTAMP}.zip"

echo "📦 Dumping all PostgreSQL databases to $SQL_FILE ..."

docker exec "${PROJECT_NAME:-lab-data-stack}_postgres" pg_dumpall -U "$POSTGRES_USER" --clean --if-exists > "$SQL_FILE"

if [ $? -ne 0 ]; then
  echo ""
  echo "❌ Backup failed. Is the stack running? Try: docker compose ps"
  echo ""
  rm -f "$SQL_FILE"
  exit 1
fi

echo "🗜️  Zipping dump + credentials into $ZIP_FILE ..."
zip -j "$ZIP_FILE" "$SQL_FILE" .env
rm -f "$SQL_FILE"

SIZE=$(du -sh "$ZIP_FILE" | cut -f1)

echo ""
echo "✅ Backup complete: $ZIP_FILE ($SIZE)"
echo "   Contains: $SQL_FILE + .env (credentials)"
echo ""
echo "⚠️  Store this file somewhere safe — it is NOT backed up by git."
echo "   Options: external drive, cloud storage, or a secure remote server."
echo ""
