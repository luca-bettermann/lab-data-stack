#!/bin/bash
# ============================================================
# Lab Data Stack — lib.sh
# Shared functions for all scripts. Source this file, don't run it.
# ============================================================

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

# ─── .env helpers ────────────────────────────────────────────

# require_env [message]
# Exits with error if .env is missing.
require_env() {
  local msg="${1:-Run from the project directory where .env lives.}"
  if [ ! -f .env ]; then
    echo ""
    echo "No .env file found."
    echo "  $msg"
    echo ""
    exit 1
  fi
}

# require_env_vars VAR1 VAR2 ...
# Exits if any of the listed variables are unset or empty.
require_env_vars() {
  local missing=()
  for var in "$@"; do
    if [ -z "${!var:-}" ]; then
      missing+=("$var")
    fi
  done
  if [ ${#missing[@]} -gt 0 ]; then
    echo ""
    printf "  ${RED}Missing required env vars:${NC}\n"
    for var in "${missing[@]}"; do
      echo "    - $var"
    done
    echo ""
    echo "  Check your .env file or re-run ./install.sh"
    echo ""
    exit 1
  fi
}

# ─── Secret generation ──────────────────────────────────────

gen_secret() {
  openssl rand -base64 42 | tr -d '\n/+=' | cut -c1-42
}

# ─── Interactive prompts ─────────────────────────────────────

_REPLY=""

# prompt_value LABEL PROPOSED [required=false]
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

    if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1024 ] || [ "$port" -gt 65535 ]; then
      printf "  ${RED}Enter a valid port (1024–65535).${NC}\n"
      proposed="$port"
      continue
    fi

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

# mask VALUE — show first 4 chars then asterisks
mask() {
  local val="$1"
  echo "${val:0:4}$(printf '%0.s*' {1..12})"
}

# ─── Dependency check ────────────────────────────────────────

check_dependencies() {
  echo ""
  echo "Checking dependencies..."
  local all_ok=true

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

  if docker compose version &>/dev/null 2>&1; then
    printf "  ${GREEN}✓${NC} docker compose (v2)\n"
  else
    printf "  ${RED}✗${NC} docker compose (v2) — not found\n"
    echo "    Docker Compose v2 is bundled with Docker Desktop."
    echo "    Standalone install: https://docs.docker.com/compose/install/"
    all_ok=false
  fi

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

# ─── PostgreSQL backup/restore ───────────────────────────────

# pg_backup_dump PROJECT_NAME POSTGRES_USER OUTPUT_FILE
# Runs pg_dumpall inside the postgres container.
pg_backup_dump() {
  local project="${1:-lab-data-stack}"
  local user="$2"
  local output="$3"

  docker exec "${project}_postgres" pg_dumpall -U "$user" --clean --if-exists > "$output"
}

# pg_restore_dump PROJECT_NAME POSTGRES_USER INPUT_FILE
# Pipes a SQL dump into the postgres container.
pg_restore_dump() {
  local project="${1:-lab-data-stack}"
  local user="$2"
  local input="$3"

  cat "$input" | docker exec -i "${project}_postgres" psql -U "$user" postgres
}
