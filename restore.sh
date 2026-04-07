#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

if [ -z "$1" ]; then
  echo ""
  echo "No backup file specified."
  echo "  Usage: ./restore.sh backup-20240101-1200.zip"
  echo ""
  exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
  echo ""
  echo "File not found: $BACKUP_FILE"
  echo ""
  exit 1
fi

WORK_DIR="$(mktemp -d)"
echo ""
echo "Extracting $BACKUP_FILE ..."
unzip -q "$BACKUP_FILE" -d "$WORK_DIR"

SQL_FILE="$(ls "$WORK_DIR"/*.sql 2>/dev/null | head -1)"
ENV_FILE="$(ls "$WORK_DIR"/.env 2>/dev/null | head -1)"

if [ -z "$SQL_FILE" ]; then
  echo "No .sql file found inside $BACKUP_FILE"
  rm -rf "$WORK_DIR"
  exit 1
fi

if [ -n "$ENV_FILE" ]; then
  echo "Restoring credentials from backup."
  cp "$ENV_FILE" .env
else
  echo "No .env found inside the zip (older backup format)."
  if [ ! -f .env ]; then
    echo "No .env present either. Cannot proceed without credentials."
    rm -rf "$WORK_DIR"
    exit 1
  fi
  echo "  Falling back to existing .env."
  echo ""
  read -p "  Continue? [y/N] " CONFIRM_ENV
  if [[ "$CONFIRM_ENV" != "y" && "$CONFIRM_ENV" != "Y" ]]; then
    echo "Aborted."
    rm -rf "$WORK_DIR"
    exit 1
  fi
fi

source .env

echo ""
echo "WARNING: This will overwrite ALL existing data in the database."
echo "  Backup file : $BACKUP_FILE"
echo "  SQL dump    : $(basename "$SQL_FILE")"
echo ""
read -p "  Type YES to confirm: " CONFIRM
echo ""

if [ "$CONFIRM" != "YES" ]; then
  echo "Aborted."
  rm -rf "$WORK_DIR"
  exit 1
fi

echo "Stopping stack..."
docker compose down

echo "Starting PostgreSQL only..."
docker compose up -d postgres

echo "Waiting for PostgreSQL to be ready..."
until docker compose exec -T postgres pg_isready -U "$POSTGRES_USER" -d postgres > /dev/null 2>&1; do
  sleep 2
done

SAFETY_TIMESTAMP="$(date +%Y%m%d-%H%M)"
SAFETY_SQL="pre-restore-backup-${SAFETY_TIMESTAMP}.sql"
SAFETY_ZIP="pre-restore-backup-${SAFETY_TIMESTAMP}.zip"
echo "Taking safety backup of current state -> $SAFETY_ZIP ..."
pg_backup_dump "${PROJECT_NAME:-lab-data-stack}" "$POSTGRES_USER" "$SAFETY_SQL"
zip -j "$SAFETY_ZIP" "$SAFETY_SQL" .env && rm -f "$SAFETY_SQL"
echo "  If restore goes wrong, recover with: ./restore.sh $SAFETY_ZIP"
echo ""

echo "Restoring from $(basename "$SQL_FILE") ..."
pg_restore_dump "${PROJECT_NAME:-lab-data-stack}" "$POSTGRES_USER" "$SQL_FILE"

rm -rf "$WORK_DIR"

echo ""
echo "Starting full stack..."
docker compose up -d

echo ""
echo "Restore complete."
echo ""
