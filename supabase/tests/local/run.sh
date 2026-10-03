#!/usr/bin/env bash
# Runs the migrations + behavioural tests against a throwaway local Postgres.
# Requires Postgres server binaries (initdb, pg_ctl) on PATH or in PG_BIN.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
MIGRATIONS="$HERE/../../migrations"
PG_BIN="${PG_BIN:-$(dirname "$(command -v initdb 2>/dev/null || ls /usr/lib/postgresql/*/bin/initdb | tail -1)")}"
PORT="${PORT:-54329}"
DATA="$(mktemp -d)"
trap '"$PG_BIN/pg_ctl" -D "$DATA" -m immediate stop >/dev/null 2>&1 || true; rm -rf "$DATA"' EXIT

if [ "$(id -u)" = "0" ]; then
  echo "Run as a non-root user (Postgres refuses to run as root)." >&2
  exit 1
fi

"$PG_BIN/initdb" -D "$DATA" -U postgres -A trust >/dev/null
"$PG_BIN/pg_ctl" -D "$DATA" -o "-p $PORT -k $DATA -c listen_addresses=''" -w start >/dev/null
PSQL=(psql -h "$DATA" -p "$PORT" -U postgres -d postgres -v ON_ERROR_STOP=1 -q)

"${PSQL[@]}" -f "$HERE/stubs.sql"
for f in "$MIGRATIONS"/*.sql; do
  echo "Applying $(basename "$f")"
  "${PSQL[@]}" -f "$f"
done
"${PSQL[@]}" -f "$HERE/rls_test.sql"
