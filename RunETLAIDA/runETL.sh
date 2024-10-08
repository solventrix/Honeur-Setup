#!/usr/bin/env bash
set -ex

REGISTRY=harbor.honeur.org
REPOSITORY=library
IMAGE=etl-runner
VERSION=1.1.3
TAG=$VERSION

DATA_FOLDER_HOST=${PWD}/data
LOG_FOLDER_HOST=${PWD}/log
QA_FOLDER_HOST=${PWD}/qa

echo "Pull ETL runner image"
docker pull $REGISTRY/$REPOSITORY/$IMAGE:$TAG

echo "Download ETL questions"
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/RunETLAIDA/questions.json --output ${PWD}/questions.json

touch etl-runner.env
echo "THERAPEUTIC_AREA=honeur" >> etl-runner.env
echo "REGISTRY=$REGISTRY" >> etl-runner.env
echo "DATA_SET=AIDA" >> etl-runner.env
echo "ORGANIZATION=AIDA" >> etl-runner.env
echo "INDICATION=mm" >> etl-runner.env
echo "LOG_LEVEL=INFO" >> etl-runner.env
echo "LOG_FOLDER_HOST=$LOG_FOLDER_HOST" >> etl-runner.env
echo "LOG_FOLDER=/log" >> etl-runner.env
echo "ETL_IMAGE_NAME=etl-aida/etl" >> etl-runner.env
echo "ETL_IMAGE_TAG=current" >> etl-runner.env
echo "DATA_FOLDER_HOST=$DATA_FOLDER_HOST" >> etl-runner.env
echo "DATA_FOLDER=/data" >> etl-runner.env
echo "DATA_FILE=aida_data.csv" >> etl-runner.env
echo "QA_FOLDER_HOST=$QA_FOLDER_HOST" >> etl-runner.env
echo "CDM_SCHEMA=omopcdm_aida" >> etl-runner.env
echo "VOCAB_SCHEMA=omopcdm_aida" >> etl-runner.env
echo "RESULTS_SCHEMA=results_aida" >> etl-runner.env
echo "DELIMITER=," >> etl-runner.env
echo "RUN_DQD=yes" >> etl-runner.env
echo "SCRIPT_UUID=30220b6a-a1c2-4e72-8ad3-f0873f53908b" >> etl-runner.env
echo "SHARED_SCRIPT_VERSION_UUID=2661ee6e-c099-42a9-a5dd-47665c2b2014" >> etl-runner.env

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
