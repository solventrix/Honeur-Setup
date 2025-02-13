#!/usr/bin/env bash
set -ex

REGISTRY=harbor.honeur.org
REPOSITORY=study_45
IMAGE=post-bcma-feasibility
VERSION=V1
TAG=$VERSION

echo "Docker login @ $REGISTRY"
docker login $REGISTRY

echo "Pull Docker image"
docker pull $REGISTRY/$REPOSITORY/$IMAGE:$TAG

docker run --rm --name post-bcma-feasibility \
--env THERAPEUTIC_AREA=HONEUR --env SCRIPT_UUID=692d502f-59d4-4f06-ae3a-f171d59bb9b0 \
-v "$PWD/post-bcma-feasibility-results":/script/results \
--network feder8-net \
$REGISTRY/$REPOSITORY/$IMAGE:$TAG
