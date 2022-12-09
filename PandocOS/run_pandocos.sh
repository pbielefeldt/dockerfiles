#!/usr/bin/env bash

#sudo systemctl start docker

export SHARED_DIR="${HOME}/DockerShared"
export DOCKER_TAG="pbielefeldt/pandocos:latest"

#if [[ ! -d ${SHARED_DIR} ]]; then
#  mkdir -p ${SHARED_DIR}
#fi
echo -e "mounting $SHARED_DIR as /mnt/shared"

docker run --rm -i -t \
  --name my_pandoc \
  -v ${SHARED_DIR}:/mnt/shared \
  ${DOCKER_TAG}
