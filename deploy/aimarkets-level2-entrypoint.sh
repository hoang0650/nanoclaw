#!/bin/sh
# Aimarkets mức 2: full NanoClaw host (dashboard + pusher wired in dist/index.js).
# Requires /var/run/docker.sock for DockerSessionDriver.
# Docker images have no .git — stamp upgrade-state so the tripwire accepts version match.
set -eu
cd /app
mkdir -p /app/data
node --input-type=module -e "import { writeUpgradeState } from './dist/upgrade-state.js'; writeUpgradeState({ via: 'aimarkets-level2' });"
exec node dist/index.js
