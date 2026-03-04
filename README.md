# Lab Data Stack

A self-hosted data management and visualisation stack running in Docker.

| Service | Purpose | URL |
|---|---|---|
| **PostgreSQL 15** | Central database | internal only |
| **NocoDB** | Spreadsheet-like data entry & management | http://localhost:8080 |
| **Apache Superset** | Charts, graphs, and dashboards | http://localhost:8088 |

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [First-Time Setup](#2-first-time-setup)
3. [Starting the Stack](#3-starting-the-stack)
4. [Verifying Everything Works](#4-verifying-everything-works)
5. [NocoDB: Fresh Start vs. Migrating from SQLite](#5-nocodb-fresh-start-vs-migrating-from-sqlite)
6. [Connecting Superset to Your PostgreSQL Data](#6-connecting-superset-to-your-postgresql-data)
7. [Day-to-Day Operations](#7-day-to-day-operations)
8. [Deploying to a Shared Lab Server](#8-deploying-to-a-shared-lab-server)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. Prerequisites

Before you begin, make sure you have:

- **Docker Desktop** installed and running (the whale icon in your menu bar)
- **Docker Compose V2** — verify with:
  ```bash
  docker compose version
  # Should print: Docker Compose version v2.x.x
  ```
- The project files (this repository) cloned or copied to your machine

> **Apple Silicon (M1/M2/M3/M4):** All three images (`postgres`, `nocodb/nocodb`,
> `apache/superset`) provide native ARM64 builds. No special configuration needed.

---

## 2. First-Time Setup

### Step 2a — Configure your environment file

The `.env` file stores passwords and secret keys. It is **never** committed to git.

```bash
# Navigate to the project folder
cd /path/to/lab-data-stack

# Copy the template
cp .env.example .env

# Restrict permissions (good practice — keeps secrets readable only by you)
chmod 600 .env
```

Now open `.env` in any text editor and replace **every** `changeme-...` value.

**Generate secure random secrets** with this command (run it separately for each secret):
```bash
openssl rand -base64 32
```

Your `.env` should look like this when filled in:

```env
POSTGRES_USER=labuser
POSTGRES_PASSWORD=Kx9mP2vQn...   # your generated value

NOCODB_JWT_SECRET=aBcDeFgH...    # openssl rand -base64 32

SUPERSET_SECRET_KEY=xYzAbC...    # openssl rand -base64 42

SUPERSET_ADMIN_USER=admin
SUPERSET_ADMIN_EMAIL=admin@lab.local
SUPERSET_ADMIN_PASSWORD=MyLabPass123!
```

> **Important:** Once you set `SUPERSET_SECRET_KEY` and start the stack, do not change
> it. Changing it invalidates all existing Superset sessions and stored credentials.

### Step 2b — Verify your Docker Compose version supports this setup

```bash
docker compose version
```

If it shows `v1.x.x` (the old standalone `docker-compose`), upgrade Docker Desktop
to version 4.x or newer.

---

## 3. Starting the Stack

From the project folder:

```bash
docker compose up -d
```

What `-d` does: starts containers in the background ("detached" mode) so you get
your terminal back.

**What happens on first start (takes 1–3 minutes):**

1. Docker downloads the three images (postgres, nocodb, superset) — one-time download
2. PostgreSQL starts and creates the `nocodb` and `superset` databases
3. NocoDB connects to PostgreSQL and initialises its schema
4. Superset runs database migrations, creates your admin user, and starts the web server

**Watch the startup logs in real time** (optional but useful to confirm success):
```bash
docker compose logs -f
```
Press `Ctrl+C` to stop watching logs (the containers keep running).

**Watch a single service:**
```bash
docker compose logs -f superset
```

---

## 4. Verifying Everything Works

### Check container status

```bash
docker compose ps
```

All three services should show `running` (or `healthy` once health checks pass):

```
NAME              STATUS              PORTS
lab_postgres      running (healthy)
lab_nocodb        running (healthy)   0.0.0.0:8080->8080/tcp
lab_superset      running             0.0.0.0:8088->8088/tcp
```

### Test NocoDB

Open http://localhost:8080 in your browser.

- First time: you'll see a sign-up page. Create your NocoDB account.
- After signing up: you'll land on the NocoDB dashboard.
- Confirm it's using PostgreSQL: go to **Team & Settings -> Integrations** —
  you should see a PostgreSQL connection listed, not a SQLite file path.

### Test Superset

Open http://localhost:8088 in your browser.

- Log in with the credentials you set in `.env`:
  - Username: value of `SUPERSET_ADMIN_USER` (default: `admin`)
  - Password: value of `SUPERSET_ADMIN_PASSWORD`
- You should see the Superset home page.

> **Superset takes longer to start** — it runs database migrations and initialisation
> on first boot. If you get a connection error at :8088, wait 60–90 seconds and
> try again. Watch `docker compose logs -f superset` to see when it's ready.

### Test PostgreSQL directly (optional)

```bash
docker exec -it lab_postgres psql -U labuser -c "\l"
```

You should see a list of databases including `nocodb` and `superset`.

---

## 5. NocoDB: Fresh Start vs. Migrating from SQLite

Your existing NocoDB data is at `~/nocodb/noco.db` (SQLite format).

**Recommendation: Start fresh with PostgreSQL.**

NocoDB does not provide an automatic SQLite-to-PostgreSQL migration tool.
The cleanest approach is to start fresh. Here is how to preserve your existing data:

### Option A — Export your data first (recommended if data matters)

1. **Stop the old NocoDB container** (if still running):
   ```bash
   docker ps                                    # find the old container name/id
   docker stop <your-old-nocodb-container-id>
   ```
2. Open your old NocoDB at its previous URL.
3. For each table: click the table -> **...** menu -> **Download -> CSV**.
4. Save the CSV files somewhere safe on your Mac.
5. Start the new stack (Step 3 above).
6. In the new NocoDB, recreate your tables and import the CSVs:
   click **+ New Table -> Import from file -> CSV**.

### Option B — Start completely fresh

If your existing NocoDB data is not important, simply start the new stack.
The old SQLite file at `~/nocodb/noco.db` is left completely untouched.

### Prevent port conflicts

The old NocoDB container (if still running) may conflict on port 8080.
Stop it before starting the new stack:

```bash
docker ps -a                                    # list all containers
docker stop <old-nocodb-container-name-or-id>   # stop the old one
```

---

## 6. Connecting Superset to Your PostgreSQL Data

Superset needs to be told where your data lives before you can make charts.

### Add the lab PostgreSQL as a data source

1. Log in to Superset at http://localhost:8088
2. Click **Settings** (gear icon, top right) -> **Database Connections**
3. Click **+ Database** (top right button)
4. Choose **PostgreSQL** from the list
5. Fill in the connection form:

   | Field | Value | Where it comes from |
   |---|---|---|
   | Display Name | `Lab PostgreSQL` | Any name you choose |
   | Host | `postgres` | The service name in `docker-compose.yml` — Docker uses this as the internal hostname |
   | Port | `5432` | Standard PostgreSQL port, hardcoded in `docker-compose.yml` |
   | Database name | `nocodb` | Created by `init-db.sql` on first start — this is where NocoDB stores your data |
   | Username | *(your value)* | `POSTGRES_USER` in your `.env` file |
   | Password | *(your value)* | `POSTGRES_PASSWORD` in your `.env` file |

   Not sure what your username/password are? Check with:
   ```bash
   cat .env
   ```

   > **Why hostname `postgres` and not `localhost`?** Superset runs inside Docker.
   > Inside a container, `localhost` refers to the container itself — not your Mac
   > or any other container. Docker lets containers reach each other by service name,
   > so `postgres` resolves to the PostgreSQL container over the internal network.

6. Click **Test Connection** — you should see "Connection looks good!"
7. Click **Connect**

You can now create charts from any table in the `nocodb` database.

---

## 7. Day-to-Day Operations

### Start the stack
```bash
docker compose up -d
```

### Stop the stack (all data is preserved in Docker volumes)
```bash
docker compose down
```

### Restart a single service
```bash
docker compose restart nocodb
docker compose restart superset
docker compose restart postgres
```

### View logs
```bash
docker compose logs -f           # all services, streaming
docker compose logs -f superset  # one service
docker compose logs --tail=50    # last 50 lines, no streaming
```

### Check service health
```bash
docker compose ps
```

### Update images to newer versions
```bash
docker compose pull      # download latest images
docker compose up -d     # restart containers with new images
```

> **Before updating:** create a database backup first (see below).

### Back up PostgreSQL data

```bash
# Dump all databases to a SQL file (timestamped)
docker exec lab_postgres pg_dumpall -U labuser > backup-$(date +%Y%m%d-%H%M).sql

# Restore from a backup file
cat backup-20240101-1200.sql | docker exec -i lab_postgres psql -U labuser
```

---

## 8. Deploying to a Shared Lab Server

When you move this setup to a dedicated machine on your lab network, colleagues
can access NocoDB and Superset via the machine's IP address.

### What changes when you move to a server

Only the **URL you type in the browser** changes — everything else stays the same.
The `docker-compose.yml`, `.env`, and all config files work identically on any machine.

### Step-by-step: copying to a lab server

**On your Mac — copy the project files:**

```bash
# Replace 192.168.1.50 with your lab server's actual IP address
# Replace serveruser with the SSH username on that machine
scp -r /path/to/lab-data-stack serveruser@192.168.1.50:~/lab-data-stack
```

Or use any other file transfer method (USB, shared network folder, git clone).

**On the lab server — install Docker and start the stack:**

```bash
# Install Docker Engine (Ubuntu/Debian):
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# Log out and back in, then verify:
docker compose version

# Navigate to the project
cd ~/lab-data-stack

# Set up the environment file
cp .env.example .env
nano .env       # fill in passwords (use the same or new secrets)
chmod 600 .env

# Start the stack
docker compose up -d

# Watch startup logs
docker compose logs -f
```

**Access from any computer on the lab network:**

```
NocoDB:   http://192.168.1.50:8080
Superset: http://192.168.1.50:8088
```

Replace `192.168.1.50` with your actual server IP address.

**Find the server's IP address:**
```bash
# On Linux (on the server)
hostname -I
# or
ip addr show | grep "inet " | grep -v 127.0.0.1
```

### Open firewall ports on the server (Linux)

If colleagues cannot reach the server, the firewall may be blocking the ports:

```bash
# Ubuntu with UFW (Uncomplicated Firewall)
sudo ufw allow 8080/tcp    # NocoDB
sudo ufw allow 8088/tcp    # Superset
sudo ufw status            # confirm ports are open
```

### Make the stack start automatically on server reboot

```bash
# Enable Docker to start at boot (usually already enabled)
sudo systemctl enable docker

# The "restart: unless-stopped" in docker-compose.yml means containers
# restart automatically after crashes and after Docker itself restarts.
# Start the stack once and it will come back after reboots:
docker compose up -d
```

### Connecting Superset to PostgreSQL (on the server)

The database connection form in Superset uses the same hostname (`postgres`)
whether you're on your Mac or on the lab server — the Docker network name
never changes.

---

## 9. Troubleshooting

### A container fails to start

```bash
docker compose logs postgres
docker compose logs nocodb
docker compose logs superset
```

Read the last few lines — the error message is usually clear.

### "Port already in use" error

Something else is using port 8080 or 8088:

```bash
# Find what's using port 8080
lsof -i :8080

# Stop that process, or change the port in docker-compose.yml:
# Change "8080:8080" to "8081:8080" to expose NocoDB on port 8081
```

Note: Metabase typically runs on port 3000 — this stack avoids that port.

### Superset returns "500 Internal Server Error"

Usually means `SUPERSET_SECRET_KEY` is missing or the database isn't ready:

```bash
docker compose logs superset | grep -i "error\|key\|secret"
```

Confirm `SUPERSET_SECRET_KEY` is set in `.env` (non-empty, no spaces around `=`).

### Superset is slow to become available

Superset runs three init steps on every startup before serving requests.
On first start this takes 60–120 seconds. Watch the logs:

```bash
docker compose logs -f superset
# Wait for: "Starting Superset web server on port 8088..."
```

### NocoDB can't connect to PostgreSQL

```bash
docker compose ps postgres        # is postgres healthy?
docker compose logs postgres | tail -30
```

If postgres is healthy, check that the values in `.env` match what's in `docker-compose.yml`.

### Reset everything and start completely fresh

```bash
# WARNING: This deletes ALL data in all volumes (PostgreSQL, NocoDB, Superset)
docker compose down -v
docker compose up -d
```

### Useful diagnostic commands

```bash
# Open an interactive PostgreSQL prompt
docker exec -it lab_postgres psql -U labuser

# List all PostgreSQL databases
docker exec lab_postgres psql -U labuser -c "\l"

# List tables in the nocodb database
docker exec lab_postgres psql -U labuser -d nocodb -c "\dt"

# Check disk space used by Docker volumes
docker system df

# Remove unused Docker images (free up disk space)
docker image prune
```

---

## File Structure

```
lab-data-stack/
├── docker-compose.yml          <- Main stack definition
├── .env.example                <- Template — copy to .env and fill in
├── .env                        <- Your secrets (git-ignored)
├── .gitignore
├── init-db.sql                 <- Creates nocodb + superset databases (runs once)
├── superset/
│   ├── superset_config.py      <- Superset Python configuration
│   └── init.sh                 <- Startup: migrations + admin user + web server
└── docs/
    ├── tech-stack-overview.md  <- What each component does (non-technical)
    └── how-to-guide.md         <- Step-by-step guide for NocoDB & Superset users
```
