#!/usr/bin/env bash

TAGNAME="pbielefeldt/pandocos:test"

docker build --platform linux/amd64 --tag ${TAGNAME} .

docker login
docker push ${TAGNAME}

