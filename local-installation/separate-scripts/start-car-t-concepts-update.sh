#!/usr/bin/env bash
set -eux

REGISTRY=harbor.honeur.org
REPOSITORY=honeur
IMAGE=postgres-omopcdm-update-car-t
TAG=1.0

echo "Log into Harbor image repository"
docker login $REGISTRY

docker run --rm --name omopcdm-update-car-t --network feder8-net -v shared:/var/lib/shared $REGISTRY/$REPOSITORY/$IMAGE:$TAG
