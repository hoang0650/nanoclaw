#!/usr/bin/env bash
set -euo pipefail
CID=$(docker ps -q -f name=aimarketplace-nanoclaw-hsnvyh | head -1)
PKG=/app/node_modules/.pnpm/@nanoco+nanoclaw-dashboard@0.3.0/node_modules/@nanoco/nanoclaw-dashboard/dist
docker exec "$CID" sh -c "grep -n 'No data yet\|ingest\|overview\|503\|401\|token' $PKG/router.js $PKG/store.js $PKG/types.js $PKG/server.js 2>/dev/null | head -80"
echo '==== store.js head ===='
docker exec "$CID" head -c 4000 "$PKG/store.js"
echo
echo '==== router ingest ===='
docker exec "$CID" sh -c "grep -n -A40 'ingest' $PKG/router.js | head -100"
echo '==== ui overview token ===='
docker exec "$CID" sh -c "grep -n -iE 'token|hash|Bearer|localStorage|503|fetch' $PKG/ui/pages/overview.js $PKG/ui/layout.js 2>/dev/null | head -60"
