#!/usr/bin/env bash
set -ex

echo "Dropping PK from cost table before running the ETL"
docker exec -it postgres psql -U postgres -d OHDSI -c "ALTER TABLE omopcdm.cost DROP CONSTRAINT IF EXISTS xpk_visit_cost;ALTER TABLE omopcdm.cost DROP CONSTRAINT IF EXISTS xpk_cost;"

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
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/RunETLAMR/questions.json --output questions.json

touch etl-runner.env
echo "THERAPEUTIC_AREA=honeur" >> etl-runner.env
echo "REGISTRY=$REGISTRY" >> etl-runner.env
echo "ETL_IMAGE_NAME=etl-oncotyrol/etl" >> etl-runner.env
echo "ETL_IMAGE_TAG=current" >> etl-runner.env
echo "LOG_LEVEL=INFO" >> etl-runner.env
echo "LOG_FOLDER_HOST=$LOG_FOLDER_HOST" >> etl-runner.env
echo "LOG_FOLDER=/log" >> etl-runner.env
echo "DATA_FOLDER_HOST=$DATA_FOLDER_HOST" >> etl-runner.env
echo "DATA_FOLDER=/data" >> etl-runner.env
echo "FILENAME=amr.csv" >> etl-runner.env
echo "QA_FOLDER_HOST=$QA_FOLDER_HOST" >> etl-runner.env
echo "RUN_DQD=yes" >> etl-runner.env

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
