# ============================================================
# Custom Superset image — adds the PostgreSQL driver
# ============================================================
# The official apache/superset:latest image does not include
# any database drivers by default. This Dockerfile adds the
# official 'postgres' extra (psycopg2-binary) using the same
# 'uv' package installer the image ships with.
# ============================================================

FROM apache/superset:latest

# Switch to root to install the package
USER root

# Install the postgres extra from Superset's own pyproject.toml
# This adds psycopg2-binary==2.9.6 into the container's venv.
WORKDIR /app
RUN uv pip install -e .[postgres]

# Switch back to the non-root superset user
USER superset
