# Lab Data Stack

PostgreSQL + NocoDB + Superset, self-hosted via Docker Compose.

```
┌─────────────┐     SQL writes      ┌──────────────┐
│   NocoDB    │ ──────────────────► │  PostgreSQL  │
│  :8080      │                     │  (internal)  │
└─────────────┘                     └──────┬───────┘
                                          │ SQL reads
                                   ┌──────▼───────┐
                                   │   Superset   │
                                   │   :8088      │
                                   └──────────────┘
```

| Service | Image | Port |
|---|---|---|
| PostgreSQL 15 | `postgres:15-alpine` | internal |
| NocoDB | `nocodb/nocodb:latest` | 8080 |
| Apache Superset | custom build (psycopg2 added) | 8088 |

---

## Setup

```bash
cp .env.example .env
chmod 600 .env
# Fill in all values — generate secrets with: openssl rand -base64 32

./start.sh
```

First boot takes ~90 s while Superset runs migrations.

---

## Connecting Superset to PostgreSQL

Settings → Database Connections → + Database → PostgreSQL:

| Field | Value |
|---|---|
| Host | `postgres` (Docker service name, not `localhost`) |
| Port | `5432` |
| Database | `nocodb` |
| Username / Password | from `.env` |

---

## Backup & Restore

```bash
./backup.sh                            # → backup-YYYYMMDD-HHMM.zip
./restore.sh backup-YYYYMMDD-HHMM.zip  # restores with confirmation prompt
```

Backups contain the PostgreSQL dump and `.env`. Store them externally — they are gitignored.

---

## File structure

```
start.sh              stops + pulls latest images + starts the stack
stop.sh               stops all services
backup.sh             dumps all PostgreSQL databases into a zip
restore.sh            restores from a backup zip (creates safety backup first)
docker-compose.yml    stack definition
.env.example          template — copy to .env and fill in
init-db.sql           creates nocodb + superset databases (first start only)
superset/
  Dockerfile          extends apache/superset with psycopg2
  superset_config.py  Superset config (mounted into container)
  init.sh             db migrate + create admin + gunicorn
```
