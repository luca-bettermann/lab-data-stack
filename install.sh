#!/bin/bash
# ============================================================
# Lab Data Stack — install.sh
# Guided first-time setup: checks dependencies, collects all
# credentials interactively, writes .env, and starts the stack.
# ============================================================

set -euo pipefail

# ─── Colours ─────────────────────────────────────────────────
BOLD='\033[1m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
DIM='\033[2m'
NC='\033[0m'

# ─── OS detection ────────────────────────────────────────────
OS="$(uname -s 2>/dev/null || echo "unknown")"
case "$OS" in
  Darwin) OS_NAME="macOS" ;;
  Linux)  OS_NAME="Linux" ;;
  *)      OS_NAME="$OS" ;;
esac

# ─── Helpers ─────────────────────────────────────────────────

gen_secret() {
  # Generate a URL-safe random secret (no padding chars)
  openssl rand -base64 42 | tr -d '\n/+=' | cut -c1-42
}

_REPLY=""

# prompt_value LABEL PROPOSED [required=false]
# Prints label + proposed value, reads input.
# If user presses Enter, accepts proposed. Empty required field loops.
prompt_value() {
  local label="$1"
  local proposed="$2"
  local required="${3:-false}"

  while true; do
    echo ""
    printf "  ${BOLD}%s${NC}\n" "$label"
    if [ -n "$proposed" ]; then
      printf "  ${DIM}Proposed:${NC} %s\n" "$proposed"
      printf "  > "
      read -r _input
      _REPLY="${_input:-$proposed}"
      return 0
    else
      printf "  ${DIM}(required — no default)${NC}\n"
      printf "  > "
      read -r _input
      if [ -z "$_input" ] && [ "$required" = "true" ]; then
        printf "  ${RED}This field is required.${NC}\n"
        continue
      fi
      _REPLY="$_input"
      return 0
    fi
  done
}

# prompt_port LABEL DEFAULT_PORT
# Loops until the user provides a free, valid port number.
prompt_port() {
  local label="$1"
  local proposed="$2"

  while true; do
    echo ""
    printf "  ${BOLD}%s${NC}\n" "$label"
    printf "  ${DIM}Proposed:${NC} %s\n" "$proposed"
    printf "  > "
    read -r _input
    local port="${_input:-$proposed}"

    # Validate numeric and in range
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1024 ] || [ "$port" -gt 65535 ]; then
      printf "  ${RED}Enter a valid port (1024–65535).${NC}\n"
      proposed="$port"
      continue
    fi

    # Check if port is already in use
    local in_use=false
    if command -v lsof &>/dev/null; then
      lsof -i ":$port" -sTCP:LISTEN -t &>/dev/null && in_use=true || true
    elif command -v ss &>/dev/null; then
      ss -tlnp 2>/dev/null | grep -q ":$port " && in_use=true || true
    fi

    if [ "$in_use" = "true" ]; then
      local who=""
      if command -v lsof &>/dev/null; then
        who="$(lsof -i ":$port" -sTCP:LISTEN 2>/dev/null | awk 'NR==2 {print $1, "(PID "$2")"}' || true)"
      fi
      printf "  ${RED}Port %s is already in use%s${NC}\n" "$port" "${who:+ by $who}"
      printf "  Choose a different port.\n"
      proposed="$port"
      continue
    fi

    _REPLY="$port"
    return 0
  done
}

# ─── Dependency check ────────────────────────────────────────

check_dependencies() {
  echo ""
  echo "Checking dependencies..."
  local all_ok=true

  # docker
  if command -v docker &>/dev/null; then
    printf "  ${GREEN}✓${NC} docker\n"
  else
    printf "  ${RED}✗${NC} docker — not found\n"
    case "$OS_NAME" in
      macOS) echo "    Install: https://docs.docker.com/desktop/install/mac-install/" ;;
      Linux) echo "    Install: https://docs.docker.com/engine/install/" ;;
      *)     echo "    Install: https://docs.docker.com/get-docker/" ;;
    esac
    all_ok=false
  fi

  # docker compose (v2 — 'docker compose', not 'docker-compose')
  if docker compose version &>/dev/null 2>&1; then
    printf "  ${GREEN}✓${NC} docker compose (v2)\n"
  else
    printf "  ${RED}✗${NC} docker compose (v2) — not found\n"
    echo "    Docker Compose v2 is bundled with Docker Desktop."
    echo "    Standalone install: https://docs.docker.com/compose/install/"
    all_ok=false
  fi

  # openssl
  if command -v openssl &>/dev/null; then
    printf "  ${GREEN}✓${NC} openssl\n"
  else
    printf "  ${RED}✗${NC} openssl — not found\n"
    case "$OS_NAME" in
      macOS) echo "    Install: brew install openssl" ;;
      Linux) echo "    Install: sudo apt install openssl  (or equivalent)" ;;
      *)     echo "    Install: https://wiki.openssl.org/index.php/Binaries" ;;
    esac
    all_ok=false
  fi

  if [ "$all_ok" = "false" ]; then
    echo ""
    echo "  Install the missing dependencies above, then re-run ./install.sh"
    echo ""
    exit 1
  fi

  echo ""
}

# ─── Collect all values ──────────────────────────────────────

collect_values() {
  # ── Project name ─────────────────────────────────────────
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " Project"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  The project name is used for Docker container and"
  echo "  volume names. Use a short, lowercase identifier"
  echo "  (e.g. 'calibration', 'robolab-2026')."
  prompt_value "Project name" "" "true"
  PROJECT_NAME="$_REPLY"

  # ── PostgreSQL ───────────────────────────────────────────
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " PostgreSQL"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  prompt_value "Database username" "labuser"
  POSTGRES_USER="$_REPLY"

  prompt_value "Database password" "$(gen_secret)"
  POSTGRES_PASSWORD="$_REPLY"

  # ── NocoDB ───────────────────────────────────────────────
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " NocoDB"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  prompt_value "Admin email" "admin@lab.local"
  NOCODB_ADMIN_EMAIL="$_REPLY"

  prompt_value "Admin password" "$(gen_secret)"
  NOCODB_ADMIN_PASSWORD="$_REPLY"

  prompt_value "JWT secret (signs login sessions)" "$(gen_secret)"
  NOCODB_JWT_SECRET="$_REPLY"

  # ── Superset ─────────────────────────────────────────────
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " Apache Superset"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  printf "  ${YELLOW}⚠️  The secret key encrypts all stored credentials."
  printf " Once set, it must never change.${NC}\n"

  prompt_value "Admin username" "admin"
  SUPERSET_ADMIN_USER="$_REPLY"

  prompt_value "Admin email" "$NOCODB_ADMIN_EMAIL"
  SUPERSET_ADMIN_EMAIL="$_REPLY"

  prompt_value "Admin password" "$(gen_secret)"
  SUPERSET_ADMIN_PASSWORD="$_REPLY"

  prompt_value "Secret key" "$(gen_secret)"
  SUPERSET_SECRET_KEY="$_REPLY"

  # ── Ports ────────────────────────────────────────────────
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " Ports"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  prompt_port "NocoDB port" "8080"
  NOCODB_PORT="$_REPLY"

  prompt_port "Superset port" "8088"
  SUPERSET_PORT="$_REPLY"
}

# ─── Summary ─────────────────────────────────────────────────

mask() {
  # Show first 4 chars then asterisks
  local val="$1"
  echo "${val:0:4}$(printf '%0.s*' {1..12})"
}

show_summary() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " Summary"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  printf "  %-28s %s\n" "PROJECT_NAME"           "$PROJECT_NAME"
  echo ""
  printf "  %-28s %s\n" "POSTGRES_USER"          "$POSTGRES_USER"
  printf "  %-28s %s\n" "POSTGRES_PASSWORD"      "$(mask "$POSTGRES_PASSWORD")"
  echo ""
  printf "  %-28s %s\n" "NOCODB_ADMIN_EMAIL"     "$NOCODB_ADMIN_EMAIL"
  printf "  %-28s %s\n" "NOCODB_ADMIN_PASSWORD"  "$(mask "$NOCODB_ADMIN_PASSWORD")"
  printf "  %-28s %s\n" "NOCODB_JWT_SECRET"      "$(mask "$NOCODB_JWT_SECRET")"
  echo ""
  printf "  %-28s %s\n" "SUPERSET_ADMIN_USER"    "$SUPERSET_ADMIN_USER"
  printf "  %-28s %s\n" "SUPERSET_ADMIN_EMAIL"   "$SUPERSET_ADMIN_EMAIL"
  printf "  %-28s %s\n" "SUPERSET_ADMIN_PASSWORD" "$(mask "$SUPERSET_ADMIN_PASSWORD")"
  printf "  %-28s %s\n" "SUPERSET_SECRET_KEY"    "$(mask "$SUPERSET_SECRET_KEY")"
  echo ""
  printf "  %-28s %s\n" "NOCODB_PORT"            "$NOCODB_PORT"
  printf "  %-28s %s\n" "SUPERSET_PORT"          "$SUPERSET_PORT"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  printf "  ${DIM}Passwords are masked. Full values are written to .env${NC}\n"
}

# ─── Write .env ──────────────────────────────────────────────

write_env() {
  cat > .env <<EOF
# ============================================================
# Lab Data Stack — Environment Variables
# Generated by install.sh on $(date)
# OS: $OS_NAME
# ============================================================
# ⚠️  NEVER commit this file to git.
# ⚠️  SUPERSET_SECRET_KEY must never be changed after first start.
# ============================================================

# ── PostgreSQL ───────────────────────────────────────────────
POSTGRES_USER=$POSTGRES_USER
POSTGRES_PASSWORD=$POSTGRES_PASSWORD

# ── NocoDB ───────────────────────────────────────────────────
NOCODB_ADMIN_EMAIL=$NOCODB_ADMIN_EMAIL
NOCODB_ADMIN_PASSWORD=$NOCODB_ADMIN_PASSWORD
NOCODB_JWT_SECRET=$NOCODB_JWT_SECRET

# ── Apache Superset ──────────────────────────────────────────
SUPERSET_SECRET_KEY=$SUPERSET_SECRET_KEY
SUPERSET_ADMIN_USER=$SUPERSET_ADMIN_USER
SUPERSET_ADMIN_EMAIL=$SUPERSET_ADMIN_EMAIL
SUPERSET_ADMIN_PASSWORD=$SUPERSET_ADMIN_PASSWORD

# ── Ports ────────────────────────────────────────────────────
NOCODB_PORT=$NOCODB_PORT
SUPERSET_PORT=$SUPERSET_PORT

# ── Project ──────────────────────────────────────────────────
PROJECT_NAME=$PROJECT_NAME
EOF

  chmod 600 .env
}

# ─── Main ────────────────────────────────────────────────────

main() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  printf "  ${BOLD}Lab Data Stack — Installation${NC}  ${DIM}($OS_NAME)${NC}\n"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  check_dependencies

  # Warn if .env already exists
  if [ -f .env ]; then
    echo ""
    printf "  ${YELLOW}⚠️  A .env file already exists.${NC}\n"
    printf "  Overwriting it will replace all current credentials.\n"
    printf "  Continue? [y/N] "
    read -r _confirm
    if [[ "$_confirm" != "y" && "$_confirm" != "Y" ]]; then
      echo "  Aborted. Existing .env left unchanged."
      echo ""
      exit 0
    fi
  fi

  # Collect → summarise → confirm loop
  while true; do
    collect_values
    show_summary

    echo ""
    printf "  Write .env and start the stack? [Y/n/r (restart prompts)] "
    read -r _choice
    echo ""

    case "$(printf '%s' "$_choice" | tr '[:upper:]' '[:lower:]')" in
      ""| y | yes)
        write_env
        echo ""
        printf "  ${GREEN}✓ .env written${NC}\n"
        echo ""
        ./start.sh
        exit 0
        ;;
      n | no)
        echo "  Aborted. No files written."
        echo ""
        exit 0
        ;;
      r | restart)
        echo "  Restarting prompts..."
        continue
        ;;
      *)
        echo "  Please enter y, n, or r."
        continue
        ;;
    esac
  done
}

main
