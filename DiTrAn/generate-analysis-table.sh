#!/usr/bin/env bash
set -ex

REGISTRY=harbor.honeur.org
REPOSITORY=distributed-analytics
IMAGE=analysis-table-generator
VERSION=1.1.10
TAG=$VERSION

docker pull $REGISTRY/$REPOSITORY/$IMAGE:$TAG

docker run --rm --name analysis-table-generator \
--env THERAPEUTIC_AREA=HONEUR --env VERSION=$VERSION \
-v ${PWD}/results:/script/results \
--network feder8-net \
$REGISTRY/$REPOSITORY/$IMAGE:$TAG
