#!/usr/bin/env bash

TAGNAME="pbielefeldt/genfit:latest"

docker build --platform linux/amd64 --tag ${TAGNAME} .

docker login
docker push ${TAGNAME}

