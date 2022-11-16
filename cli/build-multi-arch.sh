#!/usr/bin/env bash
set -eux

VERSION=2.0.19
TAG=$VERSION

docker buildx build --platform linux/amd64,linux/arm64 --no-cache --pull --push -f "Dockerfile" -t $THERAPEUTIC_AREA_URL/library/install-script:$TAG "."
