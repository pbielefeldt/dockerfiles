#!/bin/bash
# Entrypoint: load the allsources (ROOT, Geant4, ...) + explora environment, then run the command.
# /etc/explora.env is generated at image build time from thistr16.sh and thisexplora.sh
# (see Dockerfile); login shells get it via /etc/profile.d/explora.sh.
source /etc/explora.env
exec "$@"
