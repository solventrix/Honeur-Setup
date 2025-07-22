#!/usr/bin/env bash
set -ex

REGISTRY=harbor.honeur.org
REPOSITORY=honeur
IMAGE=postgres-omopcdm-update-custom-concepts
VERSION=latest
TAG=$VERSION

docker login $REGISTRY

docker pull $REGISTRY/$REPOSITORY/$IMAGE:$TAG

docker run --rm --name omopcdm-update-custom-concepts \
-v shared:/var/lib/shared \
--env DB_HOST=postgres --env DB_PORT=5432 --env DB_OMOPCDM_SCHEMA=omopcdm_aida \
--network feder8-net \
$REGISTRY/$REPOSITORY/$IMAGE:$TAG
