#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

check_dependencies

NEW_PROJECT_NAME=""
BACKUP_FILE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --project)
      NEW_PROJECT_NAME="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: ./restore.sh backup-YYYYMMDD-HHMM.zip [--project NEW_NAME]"
      echo ""
      echo "  --project NEW_NAME   Override PROJECT_NAME from the backup's .env."
      echo "                       Useful when seeding a new stack from a no-data dump."
      echo "                       Skips the safety backup of the current state."
      exit 0
      ;;
    *)
      if [ -z "$BACKUP_FILE" ]; then
        BACKUP_FILE="$1"
        shift
      else
        echo "Unexpected argument: $1"
        exit 1
      fi
      ;;
  esac
done

if [ -z "$BACKUP_FILE" ]; then
  echo ""
  echo "No backup file specified."
  echo "  Usage: ./restore.sh backup-20240101-1200.zip [--project NEW_NAME]"
  echo ""
  exit 1
fi

if [ -n "$NEW_PROJECT_NAME" ] && ! [[ "$NEW_PROJECT_NAME" =~ ^[a-z0-9][a-z0-9_-]*$ ]]; then
  echo ""
  echo "Invalid --project name: $NEW_PROJECT_NAME"
  echo "  Must match: lowercase letters, digits, '-' or '_'."
  echo ""
  exit 1
fi

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
  if [ -n "$NEW_PROJECT_NAME" ]; then
    sed -i.bak "s|^PROJECT_NAME=.*|PROJECT_NAME=$NEW_PROJECT_NAME|" .env && rm -f .env.bak
    echo "  Project name overridden: $NEW_PROJECT_NAME"
  fi
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
require_env_vars POSTGRES_USER POSTGRES_PASSWORD PROJECT_NAME

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

echo "Pulling latest images..."
docker compose pull

echo "Starting PostgreSQL only..."
docker compose up -d postgres

echo "Waiting for PostgreSQL to be ready..."
until docker compose exec -T postgres pg_isready -U "$POSTGRES_USER" -d postgres > /dev/null 2>&1; do
  sleep 2
done

if [ -n "$NEW_PROJECT_NAME" ]; then
  echo "Skipping safety backup (--project sets a new name)."
  echo ""
else
  SAFETY_TIMESTAMP="$(date +%Y%m%d-%H%M)"
  SAFETY_SQL="pre-restore-backup-${SAFETY_TIMESTAMP}.sql"
  SAFETY_ZIP="pre-restore-backup-${SAFETY_TIMESTAMP}.zip"
  echo "Taking safety backup of current state -> $SAFETY_ZIP ..."
  pg_backup_dump "${PROJECT_NAME:-lab-data-stack}" "$POSTGRES_USER" "$SAFETY_SQL"
  zip -j "$SAFETY_ZIP" "$SAFETY_SQL" .env && rm -f "$SAFETY_SQL"
  echo "  If restore goes wrong, recover with: ./restore.sh $SAFETY_ZIP"
  echo ""
fi

echo "Restoring from $(basename "$SQL_FILE") ..."
pg_restore_dump "${PROJECT_NAME:-lab-data-stack}" "$POSTGRES_USER" "$SQL_FILE"

rm -rf "$WORK_DIR"

echo ""
echo "Starting full stack..."
docker compose up -d

echo ""
echo "Restore complete."
echo ""
