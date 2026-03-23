#!/bin/bash

if [ ! -f .env ]; then
  echo ""
  echo "❌ No .env file found."
  echo "   Run this script from the lab-data-stack directory where .env lives."
  echo ""
  exit 1
fi

if [ -z "$1" ]; then
  echo ""
  echo "❌ No backup file specified."
  echo "   Usage: ./restore.sh backup-20240101-1200.sql"
  echo ""
  exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
  echo ""
  echo "❌ File not found: $BACKUP_FILE"
  echo ""
  exit 1
fi

source .env

echo ""
echo "⚠️  WARNING: This will overwrite ALL existing data in the database."
echo "   Backup file: $BACKUP_FILE"
echo ""
read -p "   Type YES to confirm: " CONFIRM
echo ""

if [ "$CONFIRM" != "YES" ]; then
  echo "Aborted."
  exit 1
fi

echo "🔄 Restoring from $BACKUP_FILE ..."

cat "$BACKUP_FILE" | docker exec -i "${PROJECT_NAME:-lab-data-stack}_postgres" psql -U "$POSTGRES_USER" postgres

if [ $? -ne 0 ]; then
  echo ""
  echo "❌ Restore failed. Check the output above for details."
  echo ""
  exit 1
fi

echo ""
echo "🔄 Restarting stack..."
docker compose restart

echo ""
echo "✅ Restore complete."
echo ""
