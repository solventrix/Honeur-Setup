#!/usr/bin/env bash
set -eux

VERSION=2.0.19
TAG=$VERSION
REGISTRY=harbor-uat.honeur.org
REPOSITORY=library

docker buildx build --rm --platform linux/amd64,linux/arm64 --no-cache --pull --push -f "Dockerfile" -t $REGISTRY/$REPOSITORY/install-script:$TAG "."
