#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

require_env "Copy the template: cp .env.example .env"

source .env

echo "Stopping and removing existing containers..."
docker compose down

echo "Starting stack..."
docker compose up -d

echo "Done! Services available at:"
echo "  NocoDB:   http://localhost:${NOCODB_PORT:-8080}"
echo "  Superset: http://localhost:${SUPERSET_PORT:-8088}"
