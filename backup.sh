#!/bin/bash

if [ ! -f .env ]; then
  echo ""
  echo "❌ No .env file found."
  echo "   Run this script from the lab-data-stack directory where .env lives."
  echo ""
  exit 1
fi

source .env

FILENAME="backup-$(date +%Y%m%d-%H%M).sql"

echo "📦 Dumping all PostgreSQL databases to $FILENAME ..."

docker exec lab_postgres pg_dumpall -U "$POSTGRES_USER" > "$FILENAME"

if [ $? -ne 0 ]; then
  echo ""
  echo "❌ Backup failed. Is the stack running? Try: docker compose ps"
  echo ""
  rm -f "$FILENAME"
  exit 1
fi

SIZE=$(du -sh "$FILENAME" | cut -f1)

echo ""
echo "✅ Backup complete: $FILENAME ($SIZE)"
echo ""
echo "⚠️  Store this file somewhere safe — it is NOT backed up by git."
echo "   Options: external drive, cloud storage, or a secure remote server."
echo ""
