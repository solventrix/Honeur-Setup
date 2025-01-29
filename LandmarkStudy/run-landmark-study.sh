#!/usr/bin/env bash
set -ex

REGISTRY=harbor.honeur.org
REPOSITORY=study_36
IMAGE=landmark-study
VERSION=V6
TAG=$VERSION

echo "Docker login @ $REGISTRY"
docker login $REGISTRY

echo "Pull Docker image"
docker pull $REGISTRY/$REPOSITORY/$IMAGE:$TAG

docker run --rm --name landmark-study \
--env THERAPEUTIC_AREA=HONEUR --env SCRIPT_UUID=01b1a33f-52ca-4ed3-b5ef-f27666d2b218 \
-v "$PWD/results":/script/results \
--network feder8-net \
$REGISTRY/$REPOSITORY/$IMAGE:$TAG

