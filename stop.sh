#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

require_env

source .env

echo ""
echo "Stopping ${PROJECT_NAME:-lab-data-stack}..."
docker compose down

echo ""
echo "Stack stopped. All data is preserved in Docker volumes."
echo "  Restart with: ./start.sh"
echo ""
