#!/bin/sh
# Railway wrapper for Harness Open Source. Sets Railway-friendly defaults,
# keeps every piece of state on the /data volume, then starts the server.
# Any variable set on the service overrides the default here.
set -e

fail() { echo "railway-start: $*" >&2; exit 1; }

# --- State: everything under /data (the Railway volume) -------------------
export GITNESS_GIT_ROOT="${GITNESS_GIT_ROOT:-/data}"
export GITNESS_REGISTRY_FILESYSTEM_ROOT_DIRECTORY="${GITNESS_REGISTRY_FILESYSTEM_ROOT_DIRECTORY:-/data/registry}"
# Upstream keeps uploads in ~/.gitness/blob and the SSH host key in /app/ssh,
# outside the volume. Move both onto it so they survive a redeploy.
export GITNESS_BLOBSTORE_BUCKET="${GITNESS_BLOBSTORE_BUCKET:-/data/blob}"
export GITNESS_SSH_SERVER_KEY_PATH="${GITNESS_SSH_SERVER_KEY_PATH:-/data/ssh/gitness.rsa}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/data}"
mkdir -p "$GITNESS_GIT_ROOT" "$GITNESS_BLOBSTORE_BUCKET" "$GITNESS_REGISTRY_FILESYSTEM_ROOT_DIRECTORY" "$(dirname "$GITNESS_SSH_SERVER_KEY_PATH")"

# --- HTTP and public URLs ---------------------------------------------------
export GITNESS_HTTP_PORT="${GITNESS_HTTP_PORT:-${PORT:-3000}}"
if [ -z "$GITNESS_URL_BASE" ] && [ -n "$RAILWAY_PUBLIC_DOMAIN" ]; then
  export GITNESS_URL_BASE="https://${RAILWAY_PUBLIC_DOMAIN}"
fi
# The container registry is served on the same public URL.
if [ -z "$GITNESS_URL_REGISTRY" ] && [ -n "$GITNESS_URL_BASE" ]; then
  export GITNESS_URL_REGISTRY="$GITNESS_URL_BASE"
fi

# --- Git over SSH: only through a Railway TCP proxy to port 3022 ------------
# The image sets GITNESS_SSH_ENABLE=true; turn it off unless a TCP proxy exists,
# so clone URLs never point at an address nobody can reach.
if [ -n "$RAILWAY_TCP_PROXY_DOMAIN" ] && [ -n "$RAILWAY_TCP_PROXY_PORT" ]; then
  export GITNESS_SSH_ENABLE=true
  export GITNESS_SSH_PORT="${GITNESS_SSH_PORT:-3022}"
  export GITNESS_URL_GIT_SSH="${GITNESS_URL_GIT_SSH:-ssh://${RAILWAY_TCP_PROXY_DOMAIN}:${RAILWAY_TCP_PROXY_PORT}}"
else
  export GITNESS_SSH_ENABLE=false
fi

# --- Gitspaces need a Docker host, which Railway doesn't have ---------------
# (the image turns them on by default)
export GITNESS_GITSPACE_ENABLE=false

# --- Sign-up: closed. The admin below can add users. ------------------------
export GITNESS_USER_SIGNUP_ENABLED="${GITNESS_USER_SIGNUP_ENABLED:-false}"

# --- Admin account created on first boot -----------------------------------
if [ -n "$GITNESS_PRINCIPAL_ADMIN_PASSWORD" ] && [ -z "$GITNESS_PRINCIPAL_ADMIN_EMAIL" ]; then
  fail "GITNESS_PRINCIPAL_ADMIN_EMAIL is empty. Set it to the admin's email address and redeploy."
fi

# --- Secrets ---------------------------------------------------------------
if [ -n "$GITNESS_ENCRYPTER_SECRET" ] && [ "${#GITNESS_ENCRYPTER_SECRET}" -ne 32 ]; then
  fail "GITNESS_ENCRYPTER_SECRET must be exactly 32 characters (it is ${#GITNESS_ENCRYPTER_SECRET})."
fi

# --- Database: Postgres from DATABASE_URL, else SQLite on the volume -------
# (the image defaults to SQLite at /data/database.sqlite)
if [ -n "$DATABASE_URL" ]; then
  export GITNESS_DATABASE_DRIVER=postgres
  case "$DATABASE_URL" in
    *sslmode=*) GITNESS_DATABASE_DATASOURCE="$DATABASE_URL" ;;
    *\?*)       GITNESS_DATABASE_DATASOURCE="${DATABASE_URL}&sslmode=disable" ;;
    *)          GITNESS_DATABASE_DATASOURCE="${DATABASE_URL}?sslmode=disable" ;;
  esac
  export GITNESS_DATABASE_DATASOURCE
  # Wait up to 90 s for Postgres (Railway starts services in parallel).
  hostport=$(echo "$DATABASE_URL" | sed -E 's#^[a-z]+://[^@]*@([^/?]+).*#\1#')
  dbhost=${hostport%:*}; dbport=${hostport##*:}
  [ "$dbport" = "$hostport" ] && dbport=5432
  i=0
  until nc -z -w 2 "$dbhost" "$dbport" 2>/dev/null; do
    i=$((i+1)); [ $i -ge 45 ] && { echo "railway-start: Postgres at $dbhost:$dbport not reachable yet, starting anyway" >&2; break; }
    sleep 2
  done
fi

echo "railway-start: base URL ${GITNESS_URL_BASE:-unset}, database ${GITNESS_DATABASE_DRIVER:-sqlite3}, ssh ${GITNESS_SSH_ENABLE}"
exec /app/gitness server "$@"
