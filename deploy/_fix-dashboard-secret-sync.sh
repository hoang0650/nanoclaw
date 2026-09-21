#!/usr/bin/env bash
set -euo pipefail

NC_SECRET=$(docker service inspect aimarketplace-nanoclaw-hsnvyh \
  --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' \
  | sed -n 's/^DASHBOARD_SECRET=//p' | head -1)
echo "NC_SECRET_LEN=${#NC_SECRET}"

API=aimarketplace-api-8q822y
echo "=== API env before ==="
docker service inspect "$API" --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' \
  | grep -iE 'NANOCLAW|AIMARKETS_SERVICE' || true

docker service update \
  --env-add "NANOCLAW_DASHBOARD_SECRET=${NC_SECRET}" \
  --env-add 'NANOCLAW_AIMARKETS_PUBLIC_URL_TEMPLATE=https://{userId}.nanoclaw.aimarkets.vn' \
  "$API" >/dev/null

echo "=== wait API task ==="
sleep 12
echo "=== API env after ==="
docker service inspect "$API" --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' \
  | grep -iE 'NANOCLAW' || true

echo "=== overview with NC secret via swarm network ==="
docker run --rm --network dokploy-network curlimages/curl:8.5.0 \
  -sS -m 12 -w '\nhttp:%{http_code}\n' \
  -H "Authorization: Bearer ${NC_SECRET}" \
  http://aimarketplace-nanoclaw-hsnvyh:3100/api/overview | head -c 500
echo

echo "=== public overview ==="
curl -sS -m 12 -w '\nhttp:%{http_code}\n' \
  -H "Authorization: Bearer ${NC_SECRET}" \
  https://6a69f224e6032a3f00de977f.nanoclaw.aimarkets.vn/api/overview | head -c 500
echo

# Hermes: force re-issue by touching domains + ensure exact Host + no http3
python3 /tmp/_apply-aimarkets-user-certs.py 6a69f224e6032a3f00de977f
grep -n http3 /etc/dokploy/traefik/traefik.yml && echo 'WARN http3 back' || echo 'http3 still off'
echo | openssl s_client -connect 127.0.0.1:443 -servername 6a69f224e6032a3f00de977f.hermes.aimarkets.vn 2>/dev/null \
  | openssl x509 -noout -subject -issuer -dates
curl -sSI https://6a69f224e6032a3f00de977f.hermes.aimarkets.vn/login 2>/dev/null | head -15 || true
echo DONE
