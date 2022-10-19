#!/usr/bin/env bash
set -eux

VERSION=2.0.19
TAG=$VERSION

REPOSITORY=library

REGISTRY=harbor.honeur.org
docker buildx build --rm --platform linux/amd64,linux/arm64 --no-cache --pull --push -f "Dockerfile" -t $REGISTRY/$REPOSITORY/install-script:$TAG "."

REGISTRY=harbor.athenafederation.org
docker buildx build --rm --platform linux/amd64,linux/arm64 --no-cache --pull --push -f "Dockerfile" -t $REGISTRY/$REPOSITORY/install-script:$TAG "."

REGISTRY=harbor.lupusnet.org
docker buildx build --rm --platform linux/amd64,linux/arm64 --no-cache --pull --push -f "Dockerfile" -t $REGISTRY/$REPOSITORY/install-script:$TAG "."

REGISTRY=harbor.esfurn.org
docker buildx build --rm --platform linux/amd64,linux/arm64 --no-cache --pull --push -f "Dockerfile" -t $REGISTRY/$REPOSITORY/install-script:$TAG "."

REGISTRY=harbor.phederation.org
docker buildx build --rm --platform linux/amd64,linux/arm64 --no-cache --pull --push -f "Dockerfile" -t $REGISTRY/$REPOSITORY/install-script:$TAG "."