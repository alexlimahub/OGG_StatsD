#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

docker compose "$@" up -d
docker logs -f ogg-setup
exit "$(docker wait ogg-setup)"
