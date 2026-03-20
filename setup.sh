#!/bin/bash

if [ ! -f .env ]; then
  echo ""
  echo "❌ No .env file found."
  echo "👉 To get started:"
  echo "   1. Copy the template:  cp .env.example .env"
  echo "   2. Fill in all values in .env (use your password manager)"
  echo "   3. Adjust ports if running multiple instances"
  echo "   4. Run ./setup.sh again"
  echo ""
  exit 1
fi

echo "🛑 Stopping and removing existing containers..."
docker compose down

echo "🚀 Starting stack..."
docker compose up -d

echo "✅ Done! Services available at:"
echo "  NocoDB:   http://localhost:8080"
echo "  Superset: http://localhost:8088"
