#!/bin/sh
# Aimarkets mức 2: full NanoClaw host (dashboard + pusher wired in dist/index.js).
# Requires /var/run/docker.sock for DockerSessionDriver.
# Docker images have no .git — stamp upgrade-state so the tripwire accepts version match.
set -eu
cd /app
mkdir -p /app/data
export NANOCLAW_INSTALL_ID="${NANOCLAW_INSTALL_ID:-aimarkets}"

# Agent containers are started by the host Docker daemon through docker.sock, so
# every bind-mount source (groups/, data/, container/agent-runner/src, …) must
# exist at the same absolute path on the VPS. NANOCLAW_RUNTIME_ROOT names a host
# directory bind-mounted at that same path; the host runs from there.
RUNTIME_ROOT="${NANOCLAW_RUNTIME_ROOT:-}"
RUN_AS=""
if [ -n "$RUNTIME_ROOT" ] && [ "$RUNTIME_ROOT" != "/app" ]; then
  mkdir -p "$RUNTIME_ROOT"
  # Code is refreshed from the image on every start; state dirs persist.
  for entry in /app/* /app/.[!.]*; do
    [ -e "$entry" ] || continue
    name=$(basename "$entry")
    case "$name" in
      data|groups|store|logs|node_modules) continue ;;
    esac
    rm -rf "${RUNTIME_ROOT:?}/$name"
    cp -a "$entry" "$RUNTIME_ROOT/$name"
  done
  ln -sfn /app/node_modules "$RUNTIME_ROOT/node_modules"
  mkdir -p "$RUNTIME_ROOT/data" "$RUNTIME_ROOT/groups" "$RUNTIME_ROOT/store" "$RUNTIME_ROOT/logs"
  # One-time move from the old named volume (/app/data) and the image's groups/.
  if [ ! -e "$RUNTIME_ROOT/data/v2.db" ] && [ -e /app/data/v2.db ]; then
    echo "[aimarkets] migrating /app/data → $RUNTIME_ROOT/data"
    cp -a /app/data/. "$RUNTIME_ROOT/data/"
    rm -f "$RUNTIME_ROOT"/data/*.sock
  fi
  if [ -z "$(ls -A "$RUNTIME_ROOT/groups")" ] && [ -d /app/groups ]; then
    cp -a /app/groups/. "$RUNTIME_ROOT/groups/"
  fi
  cd "$RUNTIME_ROOT"
  # Agents run as the image's node user (uid 1000) and write into these dirs, so
  # the host must create them as that uid too (root host → agent gets EACCES).
  HOST_UID="${NANOCLAW_HOST_UID:-1000}"
  SOCK_GID=$(stat -c %g /var/run/docker.sock)
  RUN_AS="env HOME=/home/node setpriv --reuid=$HOST_UID --regid=$HOST_UID --groups=$SOCK_GID"
fi

node --input-type=module -e "import { writeUpgradeState } from './dist/upgrade-state.js'; writeUpgradeState({ via: 'aimarkets-level2' });"
if [ -n "$RUN_AS" ]; then
  chown -R "$HOST_UID:$HOST_UID" data groups store logs
fi

# The agent image lives only in the host daemon and image cleanup can remove it
# while no agent is running. Pull the CI-built NANOCLAW_AGENT_IMAGE_REF on start
# and whenever the local tag is missing; build on the VPS only if that fails.
if [ "${NANOCLAW_AGENT_IMAGE_AUTOBUILD:-1}" = "1" ]; then
  AGENT_IMAGE="${CONTAINER_IMAGE:-$(node --input-type=module -e "import { getDefaultContainerImage } from './dist/install-slug.js'; console.log(getDefaultContainerImage(process.cwd()));")}"
  AGENT_IMAGE_REF="${NANOCLAW_AGENT_IMAGE_REF:-}"
  (
    first=1
    while :; do
      if [ -n "$AGENT_IMAGE_REF" ] && { [ "$first" = 1 ] || ! docker image inspect "$AGENT_IMAGE" >/dev/null 2>&1; }; then
        if docker pull -q "$AGENT_IMAGE_REF" >/dev/null && docker tag "$AGENT_IMAGE_REF" "$AGENT_IMAGE"; then
          echo "[aimarkets] agent image $AGENT_IMAGE <- $AGENT_IMAGE_REF"
        else
          echo "[aimarkets] pull $AGENT_IMAGE_REF failed (private GHCR package?)"
        fi
      fi
      if ! docker image inspect "$AGENT_IMAGE" >/dev/null 2>&1; then
        echo "[aimarkets] agent image $AGENT_IMAGE missing — building"
        bash container/build.sh build || echo "[aimarkets] agent image build failed, retrying later"
      fi
      first=0
      sleep "${NANOCLAW_AGENT_IMAGE_CHECK_SECONDS:-600}"
    done
  ) &
fi

# Public edge (Traefik → :3200): /login sets the cookie, dashboard + API stay behind it.
. /app/deploy/aimarkets-proxy/start-background.sh
# shellcheck disable=SC2086
exec $RUN_AS node dist/index.js
