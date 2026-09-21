#!/usr/bin/env bash
set -euo pipefail
CID=$(docker ps -q -f name=aimarketplace-nanoclaw-hsnvyh | head -1)
PKG=/app/node_modules/.pnpm/@nanoco+nanoclaw-dashboard@0.3.0/node_modules/@nanoco/nanoclaw-dashboard/dist
NC_SECRET=$(docker service inspect aimarketplace-nanoclaw-hsnvyh \
  --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' \
  | sed -n 's/^DASHBOARD_SECRET=//p' | head -1)

echo "=== router overview handler ==="
docker exec "$CID" sed -n '1,140p' "$PKG/router.js"
echo "=== types ==="
docker exec "$CID" cat "$PKG/types.js" | head -c 3000
echo
echo "=== getDashboardSecret ==="
docker exec "$CID" grep -n -A20 'getDashboardSecret\|dashboardSecret\|function start' "$PKG/server.js" "$PKG/index.js" | head -80

# Post a minimal valid empty snapshot
SNAP=$(cat <<'JSON'
{
  "timestamp": "2026-09-21T16:30:00.000Z",
  "assistant_name": "NanoClaw",
  "uptime": 0,
  "agent_groups": [],
  "sessions": [],
  "channels": [],
  "users": [],
  "tokens": {
    "totals": {
      "inputTokens": 0,
      "outputTokens": 0,
      "cacheReadTokens": 0,
      "cacheCreationTokens": 0
    },
    "byModel": {},
    "byGroup": {}
  },
  "context_windows": [],
  "activity": { "hours": [], "inbound": [], "outbound": [] },
  "messages": []
}
JSON
)

echo "=== ingest empty snapshot ==="
docker run --rm --network dokploy-network curlimages/curl:8.5.0 \
  -sS -m 15 -w '\nhttp:%{http_code}\n' \
  -H "Authorization: Bearer ${NC_SECRET}" \
  -H 'Content-Type: application/json' \
  -d "$SNAP" \
  http://aimarketplace-nanoclaw-hsnvyh:3100/api/ingest

echo "=== overview after ==="
docker run --rm --network dokploy-network curlimages/curl:8.5.0 \
  -sS -m 15 -w '\nhttp:%{http_code}\n' \
  -H "Authorization: Bearer ${NC_SECRET}" \
  http://aimarketplace-nanoclaw-hsnvyh:3100/api/overview | head -c 800
echo
curl -sS -m 15 -w '\npublic:%{http_code}\n' \
  -H "Authorization: Bearer ${NC_SECRET}" \
  https://6a69f224e6032a3f00de977f.nanoclaw.aimarkets.vn/api/overview | head -c 400
echo
