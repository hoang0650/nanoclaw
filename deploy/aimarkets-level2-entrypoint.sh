#!/bin/sh
# Aimarkets mức 2: full NanoClaw host (dashboard + pusher wired in dist/index.js).
# Requires /var/run/docker.sock for DockerSessionDriver.
set -eu
cd /app
exec node dist/index.js
