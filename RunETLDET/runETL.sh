#!/usr/bin/env bash
set -ex

REGISTRY=harbor.honeur.org
REPOSITORY=library
IMAGE=etl-runner
VERSION=1.1.2
TAG=$VERSION

LOG_FOLDER_HOST=${PWD}/log
QA_FOLDER_HOST=${PWD}/qa

echo "Pull ETL runner image"
docker pull $REGISTRY/$REPOSITORY/$IMAGE:$TAG

touch etl-runner.env
echo "THERAPEUTIC_AREA=honeur" >> etl-runner.env
echo "REGISTRY=$REGISTRY" >> etl-runner.env
echo "LOG_LEVEL=DEBUG" >> etl-runner.env
echo "VERBOSITY_LEVEL=DEBUG" >> etl-runner.env
echo "LOG_FOLDER_HOST=$LOG_FOLDER_HOST" >> etl-runner.env
echo "LOG_FOLDER=/log" >> etl-runner.env
echo "ETL_IMAGE_NAME=etl-det/etl" >> etl-runner.env
echo "ETL_IMAGE_TAG=v1.1.1" >> etl-runner.env
echo "QA_FOLDER_HOST=$QA_FOLDER_HOST" >> etl-runner.env
echo "DB_OMOP_DBMS=postgresql" >> etl-runner.env
echo "DB_OMOP_PORT=5432" >> etl-runner.env
echo "DB_OMOP_SERVER=postgres" >> etl-runner.env
echo "DB_OMOP_DBNAME=OHDSI" >> etl-runner.env
echo "DB_OMOP_SCHEMA=omopcdm54" >> etl-runner.env
echo "DB_SRC_DBMS=postgresql" >> etl-runner.env
echo "DB_SRC_PORT=5432" >> etl-runner.env
echo "DB_SRC_SERVER=ecrf-postgres" >> etl-runner.env
echo "DB_SRC_DBNAME=postgres" >> etl-runner.env
echo "DB_SRC_SCHEMA=opal" >> etl-runner.env
echo "RUN_DQD=true" >> etl-runner.env

curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/RunETLDET/questions-det.json --output ${PWD}/questions-det.json

echo "Run ETL"
docker run \
-it \
--rm \
--name det-etl-runner \
--env-file etl-runner.env \
-v /var/run/docker.sock:/var/run/docker.sock \
-v ${PWD}/questions-det.json:/script/questions.json \
--network feder8-net \
$REGISTRY/$REPOSITORY/$IMAGE:$TAG

echo "End of ETL run"
rm -rf etl-runner.env