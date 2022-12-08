#!/usr/bin/env bash

#sudo systemctl start docker
TAGNAME="pbielefeldt/pandocos:test"

docker build --platform linux/amd64 --tag ${TAGNAME} .

docker login
docker push ${TAGNAME}
