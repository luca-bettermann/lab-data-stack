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
# Fill in all values — use your password manager
# Generate secrets: openssl rand -base64 32
# Adjust ports if running multiple instances

chmod +x setup.sh
./setup.sh
```

`setup.sh` requires `.env` to exist — it will print instructions and exit if it doesn't. Once `.env` is in place, it stops any running containers and starts the stack fresh.

```bash
docker compose logs -f   # watch startup; Superset takes ~90 s on first boot
```

**First boot only:** Superset runs `db upgrade` + `superset init` before serving. Wait for:
```
Starting Superset web server on port 8088...
```

**NocoDB** — open http://localhost:8080, log in with `NOCODB_ADMIN_EMAIL` / `NOCODB_ADMIN_PASSWORD` from `.env`.
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

# Update images
docker compose pull && docker compose up -d
```

---

## Backup & Restore

```bash
chmod +x backup.sh restore.sh

./backup.sh                              # creates backup-YYYYMMDD-HHMM.sql
./restore.sh backup-20240101-1200.sql   # restores with confirmation prompt
```

Both scripts load credentials from `.env` automatically. SQL dumps are gitignored — store them externally (cloud storage, external drive, or a secure remote).

`pg_dumpall` covers all databases including `superset`, so dashboards, charts, and datasets are fully included in the backup.

**Restoring to a different instance:** the following values in `.env` must match the original — copy them across before running `restore.sh`:

| Variable | Why |
|---|---|
| `POSTGRES_USER` + `POSTGRES_PASSWORD` | Embedded in the dump as role definitions; NocoDB and Superset use these to connect |
| `SUPERSET_SECRET_KEY` | Used to encrypt the stored DB connection password; changing it means you must re-enter the connection in Superset after restore |

`PROJECT_NAME`, ports, `NOCODB_JWT_SECRET`, and Superset admin credentials can differ freely.

---

## Migrating to a New Server

This workflow requires no local files on the new server — only the repo (public) and the backup dump.

**Before you leave the old server:**

1. Run a final backup and copy the dump to a safe location (e.g. your laptop or cloud storage):
   ```bash
   ./backup.sh
   scp backup-YYYYMMDD-HHMM.sql you@yourlaptop:~/
   ```
   This covers all databases — `nocodb`, `superset` (dashboards, charts, datasets), and any others.

2. Store your `.env` as a secret GitHub Gist so no credentials need to travel as plain files:
   - Go to https://gist.github.com → **+** → set to **Secret**
   - Paste the contents of your `.env`, name the file `.env`, create the gist
   - Save the gist URL — you'll need it on the new server

**On the new server:**

```bash
# 1. Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER   # log out and back in

# 2. Clone the repo
git clone https://github.com/<you>/lab-data-stack.git
cd lab-data-stack

# 3. Restore .env from your secret gist
#    Open the gist URL in a browser, copy the raw content, paste into .env:
nano .env          # paste and save
chmod 600 .env

# 4. Copy the backup dump to the server
scp you@yourlaptop:~/backup-YYYYMMDD-HHMM.sql .

# 5. Restore data — this starts postgres, restores, then brings up the full stack
chmod +x setup.sh restore.sh
./restore.sh backup-YYYYMMDD-HHMM.sql
```

Access: `http://<server-ip>:8080` (NocoDB) and `http://<server-ip>:8088` (Superset).

Re-import your Superset dashboards: Dashboards → **Import** → upload the `.zip`.

Auto-restart on reboot is handled by `restart: unless-stopped` in `docker-compose.yml` combined with `systemctl enable docker`.

---

## Windows

The `.sh` scripts require bash and won't run in PowerShell or cmd directly.

**Option 1 — WSL2 (recommended)**

Install WSL2 and enable the WSL2 backend in Docker Desktop Settings → General. Then open a WSL terminal and run all scripts exactly as documented — full compatibility.

```bash
# Inside WSL terminal, from the repo directory:
./setup.sh
./backup.sh
./restore.sh backup-YYYYMMDD-HHMM.sql
```

**Option 2 — Git Bash**

Git Bash (bundled with [Git for Windows](https://git-scm.com/)) runs bash scripts and has `docker` on the path if Docker Desktop is installed. Open Git Bash and run the scripts the same way. Note: `source .env` and most Unix utilities work, but behaviour can differ from WSL2 in edge cases.

**Option 3 — PowerShell equivalents (no bash required)**

If you only need backup and restore, you can run the Docker commands directly in PowerShell:

```powershell
# Backup
$date = Get-Date -Format "yyyyMMdd-HHmm"
docker exec lab-data-stack_postgres pg_dumpall -U labuser > "backup-$date.sql"

# Restore (replace filename and container/user as needed)
Get-Content backup-YYYYMMDD-HHMM.sql | docker exec -i lab-data-stack_postgres psql -U labuser postgres
```

Replace `lab-data-stack` with your `PROJECT_NAME` and `labuser` with your `POSTGRES_USER` from `.env`.

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

**PostgreSQL user not found** — PostgreSQL only creates the user and databases on a completely fresh volume. If a volume already exists from a previous (possibly failed) attempt, init is skipped and the user may be missing. If there is no data to keep, wipe and restart:
```bash
docker compose down -v
./setup.sh
```
If data must be preserved, create the user manually:
```bash
docker exec -it ${PROJECT_NAME}_postgres psql -U postgres -c "CREATE USER labuser WITH PASSWORD 'your-password';"
docker exec -it ${PROJECT_NAME}_postgres psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE nocodb TO labuser;"
docker exec -it ${PROJECT_NAME}_postgres psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE superset TO labuser;"
```

**Reset everything** !! deletes all data !!:
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
setup.sh                  validates .env exists, then stops + starts the stack
backup.sh                 dumps all PostgreSQL databases to backup-YYYYMMDD-HHMM.sql
restore.sh                restores a dump file with confirmation prompt
docker-compose.yml        main stack definition
.env.example              template — copy to .env and fill in manually
.gitignore
init-db.sql               creates nocodb + superset databases (runs once on first start)
superset/
  Dockerfile              extends apache/superset with psycopg2 (postgres driver)
  superset_config.py      Superset Python config (mounted into container)
  init.sh                 idempotent startup: db migrate + create admin + gunicorn
```
