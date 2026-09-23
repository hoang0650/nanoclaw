#!/bin/bash
set -euo pipefail
SVC=aimarketplace-nanoclaw-hsnvyh
# Cancel paused update; keep mounts; do NOT touch env
docker service update --update-failure-action continue "$SVC" || true
sleep 5
# Compute slug for /app (host cwd inside container)
SLUG=$(printf '%s' '/app' | sha1sum | cut -c1-8)
echo "slug=$SLUG"
docker tag nanoclaw-agent-v2-799a69b6:latest "nanoclaw-agent-v2-${SLUG}:latest"
docker tag nanoclaw-agent-v2-799a69b6:latest nanoclaw-agent-v2-aimarkets:latest
docker images | grep nanoclaw-agent | head -8
# Wait for 1/1
for i in $(seq 1 30); do
  st=$(docker service ls --format '{{.Name}} {{.Replicas}}' | awk '/aimarketplace-nanoclaw-hsnvyh /{print $2}')
  echo "replicas=$st"
  [ "$st" = "1/1" ] && break
  sleep 4
done
CID=$(docker ps -q -f name="${SVC}" | head -1)
echo CID=$CID
test -n "$CID"
docker exec "$CID" node --input-type=module -e 'import{getDefaultContainerImage}from"./dist/install-slug.js";console.log(getDefaultContainerImage("/app"))'
docker exec "$CID" node dist/cli/client.js groups create --folder market-6a69f224e6032a3f00de977f --name market-6a69f224e6032a3f00de977f
sleep 8
SECRET=$(docker inspect "$CID" --format '{{range .Config.Env}}{{println .}}{{end}}' | sed -n 's/^DASHBOARD_SECRET=//p' | head -1)
docker exec "$CID" wget -qO- --header="Authorization: Bearer ${SECRET}" http://127.0.0.1:3100/api/overview
echo
curl -sS -m 15 -o /tmp/ov.json -w 'public_http=%{http_code}\n' -H "Authorization: Bearer ${SECRET}" https://6a69f224e6032a3f00de977f.nanoclaw.aimarkets.vn/api/overview || true
head -c 400 /tmp/ov.json; echo