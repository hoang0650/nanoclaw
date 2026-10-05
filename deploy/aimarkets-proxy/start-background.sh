#!/bin/sh
# Sourced by the Aimarkets entrypoints: runs the login proxy next to the
# dashboard and restarts it if it exits. AIMARKETS_PROXY_DISABLE=1 skips it.
if [ "${AIMARKETS_PROXY_DISABLE:-0}" != "1" ]; then
  (
    while :; do
      PORT="${AIMARKETS_PROXY_PORT:-3200}" \
        DASHBOARD_UPSTREAM="http://127.0.0.1:${DASHBOARD_PORT:-3100}" \
        node /app/deploy/aimarkets-proxy/server.js || true
      sleep 2
    done
  ) &
fi
