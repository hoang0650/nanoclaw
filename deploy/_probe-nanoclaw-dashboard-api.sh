#!/usr/bin/env bash
set -euo pipefail
NC_SECRET=$(docker service inspect aimarketplace-nanoclaw-hsnvyh \
  --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' \
  | sed -n 's/^DASHBOARD_SECRET=//p' | head -1)
CID=$(docker ps -q -f name=aimarketplace-nanoclaw-hsnvyh | head -1)
echo "CID=$CID secret_len=${#NC_SECRET}"

echo "=== package files ==="
docker exec "$CID" sh -c 'find / -path "*nanoclaw-dashboard*" -name "*.js" 2>/dev/null | head -40'
docker exec "$CID" sh -c 'ls -la /root/.npm/_npx 2>/dev/null | head; ls node_modules/@nanoco 2>/dev/null; ls /app/node_modules/@nanoco 2>/dev/null; pwd; ls'

echo "=== try common ingest paths ==="
for path in /api/ingest /api/push /api/snapshot /api/overview /api/health /api/status; do
  code=$(docker run --rm --network dokploy-network curlimages/curl:8.5.0 \
    -sS -m 5 -o /tmp/out -w '%{http_code}' \
    -H "Authorization: Bearer ${NC_SECRET}" \
    -H 'Content-Type: application/json' \
    -d '{}' \
    "http://aimarketplace-nanoclaw-hsnvyh:3100${path}" || echo fail)
  echo "POST $path -> $code"
done
for path in /api/overview /api/health /api/status /api/agent-groups; do
  code=$(docker run --rm --network dokploy-network curlimages/curl:8.5.0 \
    -sS -m 5 -o /tmp/out -w '%{http_code}' \
    -H "Authorization: Bearer ${NC_SECRET}" \
    "http://aimarketplace-nanoclaw-hsnvyh:3100${path}" || echo fail)
  body=$(docker run --rm --network dokploy-network curlimages/curl:8.5.0 \
    -sS -m 5 -H "Authorization: Bearer ${NC_SECRET}" \
    "http://aimarketplace-nanoclaw-hsnvyh:3100${path}" | head -c 120)
  echo "GET $path -> $code body=$body"
done
