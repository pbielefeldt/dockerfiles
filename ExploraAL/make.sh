#!/usr/bin/env bash
#
# Build the ExploraAL image from the sources in vendor/ (run ./fetch-sources.sh first).
# The image contains private code: it is only built locally, never pushed.
#
# Env: TAGNAME (default: exploraal:dev), JOBS (default: number of CPUs),
#      CONTAINER_TOOL (default: docker if available, else podman)

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

TAGNAME="${TAGNAME:-exploraal:dev}"
JOBS="${JOBS:-$(nproc)}"
CONTAINER_TOOL="${CONTAINER_TOOL:-$(command -v docker > /dev/null && echo docker || echo podman)}"

if [ ! -f vendor/VERSIONS ]; then
	echo "error: vendor/VERSIONS not found, run ./fetch-sources.sh first" >&2
	exit 1
fi

ref_of() { awk -F'\t' -v n="$1" '$1 == n { print $3 }' vendor/VERSIONS; }

EXTRA_ARGS=()
# podman/buildah only honour the SHELL instruction with the docker image format
if "${CONTAINER_TOOL}" --version 2>/dev/null | grep -qi podman; then
	EXTRA_ARGS+=(--format docker)
fi

"${CONTAINER_TOOL}" build "${EXTRA_ARGS[@]}" \
	--platform linux/amd64 \
	--build-arg JOBS="${JOBS}" \
	--build-arg EXPLORA_REF="$(ref_of explora)" \
	--build-arg ALLSOURCES_REF="$(ref_of allsources)" \
	--tag "${TAGNAME}" \
	.
