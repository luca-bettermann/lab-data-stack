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

### Quickstart (recommended)

```bash
chmod +x setup.sh
./setup.sh
```

`setup.sh` does the following on first run:
- Generates a `.env` file with secure random secrets (`openssl rand -hex`)
- Prints the generated Postgres password and Superset admin password to the terminal — **save these**
- Runs `docker compose up -d`

On subsequent runs it skips `.env` generation (existing file is preserved) and just starts the stack.

> **Note:** `setup.sh` does not set `chmod 600 .env`. Run `chmod 600 .env` manually if this matters for your environment.

### Manual setup

```bash
cp .env.example .env
chmod 600 .env
# Edit .env — replace all changeme-... values
# Generate secrets: openssl rand -base64 32

docker compose up -d
docker compose logs -f   # watch startup; Superset takes ~90 s on first boot
```

**First boot only:** Superset runs `db upgrade` + `superset init` before serving. Wait for:
```
Starting Superset web server on port 8088...
```

**NocoDB** — open http://localhost:8080, sign up (first user becomes admin).
**Superset** — open http://localhost:8088, log in with `SUPERSET_ADMIN_USER` / `SUPERSET_ADMIN_PASSWORD` from `.env`.

---

## Connecting Superset to PostgreSQL

Settings → Database Connections → + Database → PostgreSQL:

| Field | Value | Source |
|---|---|---|
| Host | `postgres` | Docker service name (not `localhost`) |
| Port | `5432` | hardcoded in `docker-compose.yml` |
| Database | `nocodb` | created by `init-db.sql` |
| Username | your value | `POSTGRES_USER` in `.env` |
| Password | your value | `POSTGRES_PASSWORD` in `.env` |

Click **Test Connection** → **Connect**.

> `localhost` inside a container refers to the container itself, not the host or other containers. Docker resolves service names over the internal `lab_network`.

---

## Operations

```bash
docker compose up -d               # start
docker compose down                # stop (data preserved in volumes)
docker compose restart superset    # restart one service
docker compose logs -f superset    # stream logs
docker compose ps                  # health status

# Backup PostgreSQL
docker exec lab_postgres pg_dumpall -U labuser > backup-$(date +%Y%m%d-%H%M).sql

# Restore
cat backup.sql | docker exec -i lab_postgres psql -U labuser

# Update images
docker compose pull && docker compose up -d
```

---

## Lab Server Deployment

Copy files to server, install Docker, start the stack — only the browser URL changes:

```bash
# On your machine
scp -r /path/to/lab-data-stack serveruser@192.168.1.50:~/lab-data-stack

# On server (Ubuntu/Debian)
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER   # log out and back in
cd ~/lab-data-stack
chmod +x setup.sh && ./setup.sh

# Open firewall ports if needed
sudo ufw allow 8080/tcp && sudo ufw allow 8088/tcp
```

Access: `http://<server-ip>:8080` (NocoDB) and `http://<server-ip>:8088` (Superset).

Auto-restart is handled by `restart: unless-stopped` in `docker-compose.yml` + `systemctl enable docker`.

---

## Troubleshooting

**Superset 500 error** — `SUPERSET_SECRET_KEY` missing or empty in `.env`. Never change it after first start (invalidates all sessions).

**Port already in use** — find and stop the conflicting process:
```bash
lsof -i :8080
```

**NocoDB can't reach PostgreSQL** — check postgres is healthy first:
```bash
docker compose ps postgres
docker compose logs postgres | tail -20
```

**Reset everything** (deletes all data):
```bash
docker compose down -v && docker compose up -d
```

**Useful diagnostics:**
```bash
docker exec -it lab_postgres psql -U labuser        # interactive psql
docker exec lab_postgres psql -U labuser -c "\l"    # list databases
docker exec lab_postgres psql -U labuser -d nocodb -c "\dt"  # list NocoDB tables
docker system df                                     # volume disk usage
```

---

## File Structure

```
setup.sh                  generates .env + runs docker compose up -d
docker-compose.yml        main stack definition
.env.example              template — copy to .env and fill in manually
.gitignore
init-db.sql               creates nocodb + superset databases (runs once on first start)
superset/
  Dockerfile              extends apache/superset with psycopg2 (postgres driver)
  superset_config.py      Superset Python config (mounted into container)
  init.sh                 idempotent startup: db migrate + create admin + gunicorn
docs/
  how-to-guide.md         NocoDB and Superset usage reference
```
