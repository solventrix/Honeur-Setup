#!/usr/bin/env bash
set -ex

VERSION=1.1.9
TAG=$VERSION
REGISTRY=harbor.honeur.org
REPOSITORY=honeur-restricted
IMAGE=disease-explorer-data-preparation

echo "Docker login at $REGISTRY"
docker login $REGISTRY

echo "Pull image"
docker pull $REGISTRY/$REPOSITORY/$IMAGE:$TAG

echo "Run data pipeline"
docker run \
--rm \
--name ditran-data-preparation \
-v disease-explorer-config:/pipeline/data \
--env DB_ANALYSIS_TABLE_NAME=analysis_table \
--env PIPELINE_CONFIGURATION=lot \
--network feder8-net \
$REGISTRY/$REPOSITORY/$IMAGE:$TAG
