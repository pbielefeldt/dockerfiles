#!/usr/bin/env bash

export SHARED_DIR="${HOME}/DockerShared"
export IMAGE_TAG="docker.io/pbielefeldt/pandocos:latest"

#if [[ ! -d ${SHARED_DIR} ]]; then
#  mkdir -p ${SHARED_DIR}
#fi
echo -e "mounting $SHARED_DIR as /mnt/shared"

podman run --rm -i -t \
  --name my_pandoc \
  -v ${SHARED_DIR}:/mnt/shared:Z \
  ${IMAGE_TAG}
