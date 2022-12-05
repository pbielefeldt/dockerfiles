#!/usr/bin/env bash

TAGNAME="pbielefeldt/latexos:15.4"

docker build --platform linux/amd64 --tag ${TAGNAME} .

docker login
docker push ${TAGNAME}

