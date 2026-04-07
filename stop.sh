#!/bin/bash
# ============================================================
# Lab Data Stack — stop.sh
# Safely stops all running containers.
# Data is preserved in Docker volumes — nothing is deleted.
# To also remove containers: this script already does that.
# To additionally wipe all data: docker compose down -v  ⚠️
# ============================================================

if [ ! -f .env ]; then
  echo ""
  echo "❌ No .env file found. Run from the lab-data-stack directory."
  echo ""
  exit 1
fi

source .env

echo ""
echo "🛑 Stopping ${PROJECT_NAME:-lab-data-stack}..."
docker compose down

echo ""
echo "✅ Stack stopped. All data is preserved in Docker volumes."
echo "   Restart with: ./start.sh"
echo ""
