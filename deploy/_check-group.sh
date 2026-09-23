#!/bin/bash
set -euo pipefail
SVC=aimarketplace-nanoclaw-hsnvyh
CID=$(docker ps -q -f name="${SVC}" | head -1)
echo CID=$CID
docker exec "$CID" node dist/cli/client.js groups list
echo --- wait pusher ---
sleep 65
SECRET=$(docker inspect "$CID" --format "{{range .Config.Env}}{{println .}}{{end}}" | sed -n "s/^DASHBOARD_SECRET=//p" | head -1)
docker exec "$CID" wget -qO- --header="Authorization: Bearer ${SECRET}" http://127.0.0.1:3100/api/overview
echo
docker exec "$CID" printenv NANOCLAW_INSTALL_ID || echo no_install_id
docker images --format "{{.Repository}}:{{.Tag}}" | grep nanoclaw-agent
