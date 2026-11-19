#!/usr/bin/env bash
#
# Build and push the GenfitOS image with podman.
#   ./make.sh              build and push (docker.io/pbielefeldt/genfit)
#   NO_PUSH=1 ./make.sh    build only
# TAGVERSION is the GenFit tag plus a revision: raise the revision whenever the image is
# rebuilt and pushed (also for a new base image).

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

GENFIT_REF="02-03-00"
IMAGE="docker.io/pbielefeldt/genfit"
TAGVERSION="${GENFIT_REF}-2"

# --format docker: keep the image format of the docker builds so far
podman build --format docker --pull=always --platform linux/amd64 \
	--build-arg GENFIT_REF="${GENFIT_REF}" \
	--build-arg BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
	--tag "${IMAGE}:${TAGVERSION}" --tag "${IMAGE}:latest" .

if [ "${NO_PUSH:-}" = 1 ]; then
	echo "NO_PUSH=1: not pushing"
	exit 0
fi
podman login --get-login docker.io > /dev/null 2>&1 || podman login docker.io
podman push "${IMAGE}:${TAGVERSION}"
podman push "${IMAGE}:latest"
