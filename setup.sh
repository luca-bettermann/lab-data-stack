#!/bin/bash

GIST_SSH_URL="git@gist.github.com:101eb1b2d8d9d782a9458eb9d99d8dbf.git"

if [ -f .env ]; then
  echo "✅ .env file already exists, skipping fetch."
else
  echo "🔐 Fetching .env from private gist..."

  TEMP_DIR=$(mktemp -d)

  if ! git clone "$GIST_SSH_URL" "$TEMP_DIR" 2>&1; then
    rm -rf "$TEMP_DIR"
    echo ""
    echo "❌ Failed to clone private gist."
    echo "   SSH access to GitHub is required."
    echo "   Make sure your SSH key is added to your GitHub account and the ssh-agent is running."
    echo "   Test with: ssh -T git@github.com"
    exit 1
  fi

  if [ ! -f "$TEMP_DIR/.env" ]; then
    rm -rf "$TEMP_DIR"
    echo "❌ Gist cloned successfully but no .env file was found in it."
    exit 1
  fi

  cp "$TEMP_DIR/.env" .env
  rm -rf "$TEMP_DIR"
  echo "✅ .env fetched from gist."
fi

echo "🛑 Stopping and removing existing containers..."
docker compose down

echo "🚀 Starting stack..."
docker compose up -d

echo "✅ Done! Services available at:"
echo "  NocoDB:   http://localhost:8080"
echo "  Superset: http://localhost:8088"
