#!/usr/bin/env bash

GENFIT_REF="02-03-00"
TAGNAME="pbielefeldt/genfit"

docker build --platform linux/amd64 --build-arg GENFIT_REF=${GENFIT_REF} \
	--build-arg BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
	--tag ${TAGNAME}:${GENFIT_REF} --tag ${TAGNAME}:latest .

docker login
docker push ${TAGNAME}:${GENFIT_REF}
docker push ${TAGNAME}:latest
