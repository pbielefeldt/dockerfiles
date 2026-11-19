#!/usr/bin/env bash
#
# Build and push the PandocOS image with podman.
#   ./make.sh              build and push (docker.io/pbielefeldt/pandocos)
#   NO_PUSH=1 ./make.sh    build only
# Raise TAGVERSION whenever the image is rebuilt and pushed (also for a new base image).

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

IMAGE="docker.io/pbielefeldt/pandocos"
TAGVERSION="16.0.2"

# --format docker: keep the image format of the docker builds so far
podman build --format docker --pull=always --platform linux/amd64 \
	--tag "${IMAGE}:${TAGVERSION}" --tag "${IMAGE}:latest" .

if [ "${NO_PUSH:-}" = 1 ]; then
	echo "NO_PUSH=1: not pushing"
	exit 0
fi
podman login --get-login docker.io > /dev/null 2>&1 || podman login docker.io
podman push "${IMAGE}:${TAGVERSION}"
podman push "${IMAGE}:latest"
