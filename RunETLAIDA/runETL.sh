#!/usr/bin/env bash
set -ex

REGISTRY=harbor.honeur.org
REPOSITORY=library
IMAGE=etl-runner
VERSION=1.1.2
TAG=$VERSION

DATA_FOLDER_HOST=${PWD}/data
LOG_FOLDER_HOST=${PWD}/log
QA_FOLDER_HOST=${PWD}/qa

echo "Pull ETL runner image"
docker pull $REGISTRY/$REPOSITORY/$IMAGE:$TAG

echo "Download ETL questions"
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/features/AEKR-2115/RunETLAIDA/questions.json --output questions.json

touch etl-runner.env
echo "THERAPEUTIC_AREA=honeur" >> etl-runner.env
echo "REGISTRY=$REGISTRY" >> etl-runner.env
echo "LOG_LEVEL=$VERBOSITY_LEVEL" >> etl-runner.env
echo "LOG_FOLDER_HOST=$LOG_FOLDER_HOST" >> etl-runner.env
echo "LOG_FOLDER=/var/log" >> etl-runner.env
echo "ETL_IMAGE_NAME=etl-aida/etl" >> etl-runner.env
echo "ETL_IMAGE_TAG=$ETL_IMAGE_TAG" >> etl-runner.env
echo "DATA_FOLDER_HOST=$DATA_FOLDER_HOST" >> etl-runner.env
echo "DATA_FOLDER=/etl/data" >> etl-runner.env
echo "DATA_FILE=$DATA_FILE" >> etl-runner.env
echo "QA_FOLDER_HOST=$QA_FOLDER_HOST" >> etl-runner.env
echo "CDM_SCHEMA=$CDM_SCHEMA" >> etl-runner.env
echo "VOCAB_SCHEMA=$VOCAB_SCHEMA" >> etl-runner.env
echo "RESULTS_SCHEMA=$RESULTS_SCHEMA" >> etl-runner.env

echo "Run ETL"
docker run \
-it \
--rm \
--name etl-runner \
--env-file etl-runner.env \
-v /var/run/docker.sock:/var/run/docker.sock \
-v ${PWD}/questions.json:/script/questions.json \
--network feder8-net \
$REGISTRY/$REPOSITORY/$IMAGE:$TAG

echo "End of ETL run"
rm -rf etl-runner.env
