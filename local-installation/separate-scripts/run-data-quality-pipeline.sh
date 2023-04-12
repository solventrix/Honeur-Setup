#!/usr/bin/env bash
set -ex

REGISTRY=harbor.honeur.org
REPOSITORY=distributed-analytics
IMAGE=data-quality-pipeline
VERSION=1.4.0
TAG=$VERSION

QA_FOLDER_HOST=${PWD}/qa

touch data-quality-pipeline.env
#echo "DB_ANALYSIS_TABLE_SCHEMA=public" >> data-quality-pipeline.env
#echo "DB_ANALYSIS_TABLE_NAME=analysis_table" >> data-quality-pipeline.env
echo "THERAPEUTIC_AREA=honeur" >> data-quality-pipeline.env
echo "QA_FOLDER_HOST=$QA_FOLDER_HOST" >> data-quality-pipeline.env
echo "REGISTRY=$REGISTRY" >> data-quality-pipeline.env
echo "SCRIPT_UUID=9719aeb1-84c4-49c5-a2a1-c6ea3af00305" >> data-quality-pipeline.env

echo "Docker login @ $REGISTRY"
docker login $REGISTRY

docker pull $REGISTRY/$REPOSITORY/$IMAGE:$TAG

docker run \
--rm \
--name data-quality-pipeline \
--env-file data-quality-pipeline.env \
-v /var/run/docker.sock:/var/run/docker.sock \
--network feder8-net \
$REGISTRY/$REPOSITORY/$IMAGE:$TAG

rm -rf data-quality-pipeline.env
