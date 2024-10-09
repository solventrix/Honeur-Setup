#!/usr/bin/env bash
set -ex

REGISTRY=harbor.honeur.org
REPOSITORY=distributed-analytics
IMAGE=analysis-table-generator
VERSION=1.0.11

docker run --rm --name analysis-table-generator \
--env THERAPEUTIC_AREA=HONEUR --env VERSION=$VERSION \
--network feder8-net \
$REGISTRY/$REPOSITORY/$IMAGE:$VERSION
