#!/usr/bin/env bash
#
# Build, test and push the LaTeXOS image with podman.
#   ./make.sh              build, compile LaTeXOS/testfiles, push (docker.io/pbielefeldt/latexos)
#   NO_PUSH=1 ./make.sh    build and test only
# Raise TAGVERSION whenever the image is rebuilt and pushed (also for a new base image).

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

IMAGE="docker.io/pbielefeldt/latexos"
TAGVERSION="16.0.2"

# --format docker: keep the image format of the docker builds so far
podman build --format docker --pull=always --platform linux/amd64 \
	--tag "${IMAGE}:${TAGVERSION}" --tag "${IMAGE}:latest" .

# test: compile the test document in a throw-away copy, so testfiles/ stays clean
WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT
cp -a testfiles/. "${WORK}/"
podman run --rm -v "${WORK}:/work:Z" -w /work "${IMAGE}:${TAGVERSION}" /bin/sh -c "make -C /work"
test -s "${WORK}/main.pdf"
echo "test compile ok"

if [ "${NO_PUSH:-}" = 1 ]; then
	echo "NO_PUSH=1: not pushing"
	exit 0
fi
podman login --get-login docker.io > /dev/null 2>&1 || podman login docker.io
podman push "${IMAGE}:${TAGVERSION}"
podman push "${IMAGE}:latest"
