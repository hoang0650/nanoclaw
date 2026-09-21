#!/bin/sh
# Aimarkets dashboard-only mode: seed empty snapshot so Overview is not 503.
set -eu
PORT="${DASHBOARD_PORT:-3100}"
SECRET="${DASHBOARD_SECRET:-}"

seed() {
  [ -n "$SECRET" ] || return 0
  SNAP='{"timestamp":"'"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)"'","assistant_name":"NanoClaw","uptime":0,"agent_groups":[],"sessions":[],"channels":[],"users":[],"tokens":{"totals":{"inputTokens":0,"outputTokens":0,"cacheReadTokens":0,"cacheCreationTokens":0},"byModel":{},"byGroup":{}},"context_windows":[],"activity":[],"messages":[]}'
  wget -q -O /dev/null \
    --header="Authorization: Bearer ${SECRET}" \
    --header="Content-Type: application/json" \
    --post-data="$SNAP" \
    "http://127.0.0.1:${PORT}/api/ingest" 2>/dev/null || true
}

# Start dashboard in background then seed once it is up
npx --yes @nanoco/nanoclaw-dashboard &
PID=$!
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
  sleep 1
  if wget -q -O /dev/null "http://127.0.0.1:${PORT}/api/status" 2>/dev/null; then
    seed
    break
  fi
done
# Reseed every 5 minutes (in-memory store dies on process restart only; keep warm)
while kill -0 "$PID" 2>/dev/null; do
  sleep 300
  seed
done
wait "$PID"
