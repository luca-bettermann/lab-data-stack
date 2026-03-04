#!/bin/bash
# ============================================================
# Superset Initialization + Startup Script
# ============================================================
# This script runs inside the 'superset' container on every start.
# Steps 1-3 are idempotent (safe to re-run); they complete in
# seconds on subsequent restarts.
#
# Step 1: Apply database migrations
# Step 2: Create the admin user (skipped if already exists)
# Step 3: Initialise Superset roles and permissions
# Step 4: Start the Gunicorn web server (replaces this process)
# ============================================================

set -e  # Exit immediately if any command fails

echo ""
echo "============================================"
echo "  Apache Superset — Starting up"
echo "============================================"
echo ""

# ── Step 1: Database migrations ──────────────────────────────
echo "[1/4] Applying database migrations..."
echo "      (Creates tables in the 'superset' PostgreSQL database)"
superset db upgrade
echo "      Migrations complete."
echo ""

# ── Step 2: Create admin user ────────────────────────────────
echo "[2/4] Creating admin user..."
echo "      Username : ${ADMIN_USERNAME:-admin}"
echo "      Email    : ${ADMIN_EMAIL:-admin@lab.local}"

# The || true prevents the script from failing if the admin
# user already exists (which happens on every restart after
# the first one).
superset fab create-admin \
    --username  "${ADMIN_USERNAME:-admin}" \
    --firstname "Admin" \
    --lastname  "User" \
    --email     "${ADMIN_EMAIL:-admin@lab.local}" \
    --password  "${ADMIN_PASSWORD:-admin}" \
    2>&1 | grep -v "already exist" || true

echo "      Admin user ready."
echo ""

# ── Step 3: Initialise roles ─────────────────────────────────
echo "[3/4] Initialising roles and permissions..."
superset init
echo "      Roles ready."
echo ""

# ── Step 4: Start web server ─────────────────────────────────
echo "[4/4] Starting Superset web server on port 8088..."
echo ""
echo "  Access Superset at: http://localhost:8088"
echo "  (or http://<server-ip>:8088 on your lab network)"
echo ""
echo "============================================"
echo ""

# 'exec' replaces this bash process with gunicorn,
# so Docker signals (e.g. Ctrl+C) go directly to gunicorn.
exec gunicorn \
    --bind "0.0.0.0:8088" \
    --workers 2 \
    --worker-class gthread \
    --threads 20 \
    --timeout 60 \
    --access-logfile - \
    --error-logfile - \
    --limit-request-line 0 \
    --limit-request-field_size 0 \
    "superset.app:create_app()"
