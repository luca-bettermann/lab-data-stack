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

echo "🛑 Stopping stack..."
docker compose down

echo "🐘 Starting PostgreSQL only..."
docker compose up -d postgres

echo "⏳ Waiting for PostgreSQL to be ready..."
until docker compose exec -T postgres pg_isready -U "$POSTGRES_USER" -d postgres > /dev/null 2>&1; do
  sleep 2
done

SAFETY_BACKUP="pre-restore-backup-$(date +%Y%m%d-%H%M).sql"
echo "💾 Taking safety backup of current state → $SAFETY_BACKUP ..."
docker exec "${PROJECT_NAME:-lab-data-stack}_postgres" pg_dumpall -U "$POSTGRES_USER" --clean --if-exists > "$SAFETY_BACKUP"
echo "   Safety backup complete. If restore goes wrong, recover with:"
echo "   ./restore.sh $SAFETY_BACKUP"
echo ""

echo "🔄 Restoring from $BACKUP_FILE ..."
cat "$BACKUP_FILE" | docker exec -i "${PROJECT_NAME:-lab-data-stack}_postgres" psql -U "$POSTGRES_USER" postgres

echo ""
echo "🚀 Starting full stack..."
docker compose up -d

echo ""
echo "✅ Restore complete."
echo ""
