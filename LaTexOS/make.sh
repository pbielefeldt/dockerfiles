#!/usr/bin/env bash

#sudo systemctl start docker
TAGNAME="pbielefeldt/latexos"
TAGVERSION="15.5_tmptest"

docker build --platform linux/amd64 --tag ${TAGNAME}:${TAGVERSION} --tag ${TAGNAME}:latest .

#docker login
#docker push ${TAGNAME} --all-tags
