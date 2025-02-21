#!/usr/bin/env bash
set -ex

REGISTRY=harbor.honeur.org
REPOSITORY=study_36
IMAGE=landmark-study
VERSION=V7
TAG=$VERSION

echo "Docker login @ $REGISTRY"
docker login $REGISTRY

echo "Pull Docker image"
docker pull $REGISTRY/$REPOSITORY/$IMAGE:$TAG

docker run --rm --name landmark-study \
--env THERAPEUTIC_AREA=HONEUR --env SCRIPT_UUID=9cc32497-4cd0-4882-9a6a-5714c869edcc \
-v "$PWD/results":/script/results \
--network feder8-net \
$REGISTRY/$REPOSITORY/$IMAGE:$TAG

