#!/bin/bash
# ============================================================
# Lab Data Stack — install.sh
# Guided first-time setup: checks dependencies, collects all
# credentials interactively, writes .env, and starts the stack.
#
# Extensible via hook functions. Wrapper repos can:
#   1. Source this file (it won't run main when sourced)
#   2. Define ext_* hook functions for additional services
#   3. Call main
#
# Hooks:
#   ext_collect_values     — prompt for additional credentials
#   ext_collect_ports      — prompt for additional ports
#   ext_generate_defaults  — auto-generate additional credentials
#   ext_show_summary       — print additional credential rows
#   ext_show_summary_ports — print additional port rows
#   ext_write_env          — emit additional .env sections (stdout)
#   ext_write_env_ports    — emit additional port lines (stdout)
# ============================================================

set -euo pipefail

SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "$0")" && pwd)}"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$BASE_DIR/lib.sh"

# ─── Configurable labels (wrappers can override before sourcing) ─
INSTALL_TITLE="${INSTALL_TITLE:-Lab Data Stack}"
INSTALL_PROJECT_HINT="${INSTALL_PROJECT_HINT:-(e.g. 'calibration', 'robolab-2026')}"

# ─── Auto-generate all credentials ──────────────────────────

generate_defaults() {
  POSTGRES_USER="labuser"
  POSTGRES_PASSWORD="$(gen_secret)"

  NOCODB_ADMIN_EMAIL="admin@lab.local"
  NOCODB_ADMIN_PASSWORD="$(gen_secret)"
  NOCODB_JWT_SECRET="$(gen_secret)"

  SUPERSET_ADMIN_USER="admin"
  SUPERSET_ADMIN_EMAIL="admin@lab.local"
  SUPERSET_ADMIN_PASSWORD="$(gen_secret)"
  SUPERSET_SECRET_KEY="$(gen_secret)"

  if declare -f ext_generate_defaults > /dev/null 2>&1; then
    ext_generate_defaults
  fi
}

# ─── Collect all values (interactive) ────────────────────────

collect_values_interactive() {
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
  printf "  ${YELLOW}The secret key encrypts all stored credentials."
  printf " Once set, it must never change.${NC}\n"

  prompt_value "Admin username" "admin"
  SUPERSET_ADMIN_USER="$_REPLY"

  prompt_value "Admin email" "$NOCODB_ADMIN_EMAIL"
  SUPERSET_ADMIN_EMAIL="$_REPLY"

  prompt_value "Admin password" "$(gen_secret)"
  SUPERSET_ADMIN_PASSWORD="$_REPLY"

  prompt_value "Secret key" "$(gen_secret)"
  SUPERSET_SECRET_KEY="$_REPLY"

  # ── Extension hook: additional services ──────────────────
  if declare -f ext_collect_values > /dev/null 2>&1; then
    ext_collect_values
  fi
}

# ─── Collect values (main entry point) ───────────────────────

collect_values() {
  # ── Project name (always prompted) ───────────────────────
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " Project"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  The project name is used for Docker container and"
  echo "  volume names. Use a short, lowercase identifier"
  echo "  $INSTALL_PROJECT_HINT"
  prompt_value "Project name" "" "true"
  PROJECT_NAME="$_REPLY"

  # ── Auto-generate or prompt for credentials ──────────────
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " Credentials"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  All credentials are internal to the Docker stack"
  echo "  and only stored in .env — you don't need to"
  echo "  remember them."
  echo ""
  printf "  Auto-generate all credentials? [Y/n] "
  read -r _auto
  _auto="$(printf '%s' "$_auto" | tr '[:upper:]' '[:lower:]')"

  if [[ "$_auto" == "n" || "$_auto" == "no" ]]; then
    collect_values_interactive
  else
    printf "\n  ${DIM}Generating secure credentials...${NC}\n"
    generate_defaults
  fi

  # ── Ports (always prompted) ──────────────────────────────
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " Ports"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  prompt_port "NocoDB port" "8080"
  NOCODB_PORT="$_REPLY"

  prompt_port "Superset port" "8088"
  SUPERSET_PORT="$_REPLY"

  # ── Extension hook: additional ports ─────────────────────
  if declare -f ext_collect_ports > /dev/null 2>&1; then
    ext_collect_ports
  fi
}

# ─── Summary ─────────────────────────────────────────────────

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

  # ── Extension hook: additional service rows ──────────────
  if declare -f ext_show_summary > /dev/null 2>&1; then
    ext_show_summary
  fi

  echo ""
  printf "  %-28s %s\n" "NOCODB_PORT"            "$NOCODB_PORT"
  printf "  %-28s %s\n" "SUPERSET_PORT"          "$SUPERSET_PORT"

  # ── Extension hook: additional port rows ─────────────────
  if declare -f ext_show_summary_ports > /dev/null 2>&1; then
    ext_show_summary_ports
  fi

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  printf "  ${DIM}Passwords are masked. Full values are written to .env${NC}\n"
}

# ─── Write .env ──────────────────────────────────────────────

write_env() {
  cat > .env <<EOF
# ============================================================
# $INSTALL_TITLE — Environment Variables
# Generated by install.sh on $(date)
# OS: $OS_NAME
# ============================================================
# NEVER commit this file to git.
# SUPERSET_SECRET_KEY must never be changed after first start.
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
EOF

  # ── Extension hook: additional env sections ──────────────
  if declare -f ext_write_env > /dev/null 2>&1; then
    ext_write_env >> .env
  fi

  cat >> .env <<EOF

# ── Ports ────────────────────────────────────────────────────
NOCODB_PORT=$NOCODB_PORT
SUPERSET_PORT=$SUPERSET_PORT
EOF

  # ── Extension hook: additional port lines ────────────────
  if declare -f ext_write_env_ports > /dev/null 2>&1; then
    ext_write_env_ports >> .env
  fi

  cat >> .env <<EOF

# ── Project ──────────────────────────────────────────────────
PROJECT_NAME=$PROJECT_NAME
EOF

  chmod 600 .env
}

# ─── Main ────────────────────────────────────────────────────

main() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  printf "  ${BOLD}$INSTALL_TITLE — Installation${NC}  ${DIM}($OS_NAME)${NC}\n"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  check_dependencies

  if [ -f .env ]; then
    echo ""
    printf "  ${YELLOW}A .env file already exists.${NC}\n"
    printf "  Overwriting it will replace all current credentials.\n"
    printf "  Continue? [y/N] "
    read -r _confirm
    if [[ "$_confirm" != "y" && "$_confirm" != "Y" ]]; then
      echo "  Aborted. Existing .env left unchanged."
      echo ""
      exit 0
    fi
  fi

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

# Only run main if executed directly (not sourced by a wrapper)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main
fi
