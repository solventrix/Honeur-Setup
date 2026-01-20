#!/usr/bin/env bash
set -eux

REGISTRY=harbor.honeur.org
REPOSITORY=etl-wurzburg
IMAGE=treatment-counts-export
TAG=1.0.0

read -p "Source data folder [${PWD}/data]: " DATA_FOLDER_HOST
DATA_FOLDER_HOST=${DATA_FOLDER_HOST:-$PWD/data}
OUTPUT_FOLDER_HOST=${PWD}/output

docker pull $REGISTRY/$REPOSITORY/$IMAGE:$TAG

docker run --rm -it \
-v ${DATA_FOLDER_HOST}:/script/data \
-v ${OUTPUT_FOLDER_HOST}:/script/output \
$REGISTRY/$REPOSITORY/$IMAGE:$TAG
