#!/usr/bin/env bash
set -eux

VERSION=2.0.20
TAG=$VERSION
THERAPEUTIC_AREA_URL="${THERAPEUTIC_AREA_URL:=harbor-uat.honeur.org}"
REPOSITORY=library

docker buildx build --rm --platform linux/amd64,linux/arm64 --no-cache --pull --push -f "Dockerfile" -t $THERAPEUTIC_AREA_URL/$REPOSITORY/install-script:$TAG "."
