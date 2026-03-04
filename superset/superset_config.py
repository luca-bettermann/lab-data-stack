"""
Apache Superset Configuration — Lab Data Stack
===============================================
This file is mounted into the Superset container at:
  /app/pythonpath/superset_config.py

Superset automatically imports it on startup because
/app/pythonpath is in the container's PYTHONPATH.

Configuration values are read from environment variables
(set in docker-compose.yml / .env file), so you do NOT
need to edit this file directly — edit .env instead.
"""

import os

# ──────────────────────────────────────────────────────────────
# REQUIRED: Secret key
# Used to sign cookies and encrypt sensitive values.
# Set SUPERSET_SECRET_KEY in your .env file.
# ──────────────────────────────────────────────────────────────
SECRET_KEY = os.environ.get("SUPERSET_SECRET_KEY")

if not SECRET_KEY:
    raise RuntimeError(
        "SUPERSET_SECRET_KEY is not set. "
        "Add it to your .env file and restart the stack."
    )

# ──────────────────────────────────────────────────────────────
# REQUIRED: Superset's own metadata database
# Stores dashboards, charts, users, and configuration.
# This is NOT where your lab data lives — it's Superset's
# internal state. Points to the 'superset' PostgreSQL database.
# ──────────────────────────────────────────────────────────────
SQLALCHEMY_DATABASE_URI = os.environ.get(
    "DATABASE_URL",
    "postgresql+psycopg2://labuser:changeme@postgres:5432/superset",
)

# ──────────────────────────────────────────────────────────────
# Security
# ──────────────────────────────────────────────────────────────
WTF_CSRF_ENABLED = True
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SECURE = False   # Change to True when using HTTPS
SESSION_COOKIE_SAMESITE = "Lax"
TALISMAN_ENABLED = False        # Enable if deploying with HTTPS

# ──────────────────────────────────────────────────────────────
# Don't load Superset's built-in example charts on first run
# ──────────────────────────────────────────────────────────────
SUPERSET_LOAD_EXAMPLES = False

# ──────────────────────────────────────────────────────────────
# Feature flags — enables useful UI features
# ──────────────────────────────────────────────────────────────
FEATURE_FLAGS = {
    "ENABLE_TEMPLATE_PROCESSING": True,   # Jinja2 in SQL queries
    "DASHBOARD_NATIVE_FILTERS": True,     # Modern filter sidebar
    "DASHBOARD_CROSS_FILTERS": True,      # Click a chart to filter others
    "ALERT_REPORTS": False,               # Needs Redis+Celery; disabled
}

# ──────────────────────────────────────────────────────────────
# Query / row limits (safety net for large datasets)
# ──────────────────────────────────────────────────────────────
ROW_LIMIT = 10_000
VIZ_ROW_LIMIT = 10_000
SQL_MAX_ROW = 100_000

# ──────────────────────────────────────────────────────────────
# Cache — simple in-memory cache, suitable for a small team.
# For larger teams, replace with Redis-backed cache.
# ──────────────────────────────────────────────────────────────
CACHE_CONFIG = {
    "CACHE_TYPE": "SimpleCache",
    "CACHE_DEFAULT_TIMEOUT": 300,  # 5 minutes
}
DATA_CACHE_CONFIG = CACHE_CONFIG

# ──────────────────────────────────────────────────────────────
# Async queries — disabled (requires Redis + Celery worker)
# ──────────────────────────────────────────────────────────────
RESULTS_BACKEND = None
