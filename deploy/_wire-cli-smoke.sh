#!/bin/bash
set -euo pipefail
SVC=aimarketplace-nanoclaw-hsnvyh
CID=$(docker ps -q -f name="${SVC}" | head -1)
echo "CID=$CID"
test -n "$CID"

NCL='node dist/cli/client.js'

echo '=== messaging-groups create ==='
docker exec "$CID" $NCL messaging-groups create \
  --channel-type cli \
  --platform-id local \
  --name "Local CLI" || true

echo '=== wirings create ==='
docker exec "$CID" $NCL wirings create \
  --channel-type cli \
  --platform-id local \
  --agent-group-id ag-f6d60fd4-c148-4337-a247-f2fe9d83f79c \
  --session-mode shared || true

echo '=== wirings list ==='
docker exec "$CID" $NCL wirings list || true

echo '=== check API key env ==='
docker exec "$CID" sh -c 'printenv | grep -E "ANTHROPIC|CLAUDE_CODE|ONECLI" || echo NO_PROVIDER_KEY'

echo '=== send smoke message ==='
docker exec "$CID" $NCL messaging-groups send \
  --channel-type cli \
  --platform-id local \
  --text "smoke test — wake the agent" || true

sleep 8
echo '=== sessions list ==='
docker exec "$CID" $NCL sessions list || true

echo '=== docker agent containers ==='
docker ps --format '{{.Names}} {{.Status}} {{.Image}}' | grep -iE 'nanoclaw|ncl-' || echo 'no agent container yet'

echo '=== host logs (last 40) ==='
docker logs --tail 40 "$CID" 2>&1 | tail -40
