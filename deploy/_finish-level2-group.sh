#!/bin/bash
set -euo pipefail
SVC=aimarketplace-nanoclaw-hsnvyh
docker tag nanoclaw-agent-v2-799a69b6:latest nanoclaw-agent-v2-aimarkets:latest
docker images | grep nanoclaw-agent | head -5
docker service update --update-failure-action continue "$SVC" || true
sleep 3
docker service update --env-add NANOCLAW_INSTALL_ID=aimarkets "$SVC" || true
sleep 12
CID=$(docker ps -q -f name="${SVC}" | head -1)
echo CID=$CID
test -n "$CID"
docker exec "$CID" printenv NANOCLAW_INSTALL_ID || true
docker exec "$CID" node --input-type=module -e 'import{getDefaultContainerImage}from"./dist/install-slug.js";console.log(getDefaultContainerImage("/app"))'
docker exec "$CID" node dist/cli/client.js groups create --folder market-6a69f224e6032a3f00de977f --name market-6a69f224e6032a3f00de977f
sleep 5
SECRET=$(docker inspect "$CID" --format '{{range .Config.Env}}{{println .}}{{end}}' | sed -n 's/^DASHBOARD_SECRET=//p' | head -1)
docker exec "$CID" wget -qO- --header="Authorization: Bearer ${SECRET}" http://127.0.0.1:3100/api/overview
echo
docker service ls | grep nanoclaw
