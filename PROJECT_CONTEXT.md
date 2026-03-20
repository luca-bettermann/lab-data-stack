# Lab Data Stack — Project Context

Self-hosted data infrastructure for the lab: structured data entry (NocoDB), analytics/dashboards (Superset), backed by PostgreSQL. Managed via Docker Compose.

## Files

| File / Folder | Description |
|---|---|
| `setup.sh` | Automated setup: generates `.env` with secure secrets, then runs `docker compose up -d` |
| `docker-compose.yml` | Defines all three services, named volumes, and `lab_network` |
| `.env.example` | Template for manual `.env` creation |
| `init-db.sql` | Creates `nocodb` and `superset` databases on first Postgres start |
| `superset/Dockerfile` | Extends `apache/superset` with `psycopg2` for PostgreSQL support |
| `superset/superset_config.py` | Superset Python config, mounted read-only into the container |
| `superset/init.sh` | Idempotent entrypoint: runs DB migrations, creates admin, starts gunicorn |
| `docs/how-to-guide.md` | NocoDB and Superset usage reference |

## Key Points / Open Risks

- **Secrets** are generated once by `setup.sh` (hex-encoded, cryptographically random). `SUPERSET_SECRET_KEY` must never change after first start — doing so invalidates all sessions.
- **Startup order** is enforced via `depends_on: condition: service_healthy`. Superset first boot takes ~90 s.
- **`chmod 600 .env`** is not applied by `setup.sh` — must be done manually if needed.
- **NocoDB formula columns** are app-layer only and invisible to Superset; use virtual SQL datasets instead.
- Data persists in named Docker volumes (`lab_postgres_data`, `lab_nocodb_data`, `lab_superset_home`). `docker compose down -v` destroys all data.
