#!/usr/bin/env bash
set -ex

REGISTRY=harbor.honeur.org
REPOSITORY=library
IMAGE=etl-runner
VERSION=1.1.3
TAG=$VERSION

LOG_FOLDER_HOST=${PWD}/log
QA_FOLDER_HOST=${PWD}/qa

echo "Pull ETL runner image"
docker pull $REGISTRY/$REPOSITORY/$IMAGE:$TAG

touch etl-runner.env
echo "THERAPEUTIC_AREA=honeur" >> etl-runner.env
echo "REGISTRY=$REGISTRY" >> etl-runner.env
echo "LOG_LEVEL=INFO" >> etl-runner.env
echo "VERBOSITY_LEVEL=INFO" >> etl-runner.env
echo "LOG_FOLDER_HOST=$LOG_FOLDER_HOST" >> etl-runner.env
echo "LOG_FOLDER=/log" >> etl-runner.env
echo "ETL_IMAGE_NAME=etl-omop54/etl" >> etl-runner.env
echo "ETL_IMAGE_TAG=v1.2.3" >> etl-runner.env
echo "QA_FOLDER_HOST=$QA_FOLDER_HOST" >> etl-runner.env
echo "SRC_DB_53_SCHEMA=omopcdm" >> etl-runner.env
echo "RENAMED_SRC_DB_53_SCHEMA=omopcdm_53" >> etl-runner.env
echo "TARGET_DB_54_SCHEMA=omopcdm_54" >> etl-runner.env
echo "SRC_VOCAB_DB_SCHEMA=omopcdm" >> etl-runner.env
echo "SRC_RESULTS_DB_53_SCHEMA=results" >> etl-runner.env
echo "RENAMED_SRC_RESULTS_DB_53_SCHEMA=results_53" >> etl-runner.env
echo "TARGET_RESULTS_DB_54_SCHEMA=results_54" >> etl-runner.env
echo "SRC_PATIENT_CHECK_DB_SCHEMA=results" >> etl-runner.env
echo "RUN_DQD=false" >> etl-runner.env
#echo "OPENBLAS_NUM_THREADS=1" >> etl-runner.env

curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/RunETLOMOP54Conversion/questions-omop54.json --output ${PWD}/questions-omop54.json

echo "Run ETL"
docker run \
-it --rm --name etl-runner-omop54 \
--env-file etl-runner.env \
-v /var/run/docker.sock:/var/run/docker.sock \
-v ${PWD}/questions-omop54.json:/script/questions.json \
--network feder8-net \
$REGISTRY/$REPOSITORY/$IMAGE:$TAG

echo "End of ETL run"
rm -rf etl-runner.env