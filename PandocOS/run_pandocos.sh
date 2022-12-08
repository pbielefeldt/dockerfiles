#!/usr/bin/env sh

#sudo systemctl start docker

docker run --rm -i -t \
  --name my_pandoc \
  -v ~/Sammlung/Dockers/SharedVolume/:/mnt/shared \
  pbielefeldt/pandocos:test

