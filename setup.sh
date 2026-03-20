#!/bin/bash

if [ -f .env ]; then
  echo "✅ .env file already exists, skipping generation."
else
  echo "🔐 Generating new .env file..."
  
  POSTGRES_PASSWORD=$(openssl rand -hex 16)
  NOCODB_JWT_SECRET=$(openssl rand -hex 32)
  SUPERSET_SECRET_KEY=$(openssl rand -hex 32)
  SUPERSET_ADMIN_PASSWORD=$(openssl rand -hex 8)

  cat > .env << ENVEOF
POSTGRES_USER=labuser
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
NOCODB_JWT_SECRET=$NOCODB_JWT_SECRET
SUPERSET_SECRET_KEY=$SUPERSET_SECRET_KEY
SUPERSET_ADMIN_USER=admin
SUPERSET_ADMIN_EMAIL=admin@lab.local
SUPERSET_ADMIN_PASSWORD=$SUPERSET_ADMIN_PASSWORD
ENVEOF

  echo ""
  echo "================================"
  echo "   Your credentials:"
  echo "================================"
  echo "  Postgres Password:  $POSTGRES_PASSWORD"
  echo "  Superset User:      admin"
  echo "  Superset Password:  $SUPERSET_ADMIN_PASSWORD"
  echo "================================"
  echo ""
fi

echo "🛑 Stopping and removing existing containers..."
docker compose down

echo "🚀 Starting stack..."
docker compose up -d

echo "✅ Done! Services available at:"
echo "  NocoDB:   http://localhost:8080"
echo "  Superset: http://localhost:8088"
