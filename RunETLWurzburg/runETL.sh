#!/usr/bin/env bash
set -ex

IMAGE=etl-runner
VERSION=1.1.2
TAG=$VERSION
REGISTRY=harbor.honeur.org
REPOSITORY=library
DATA_FOLDER_HOST=${PWD}/data
DATA_FOLDER=/script/etl/data
QA_FOLDER_HOST=${PWD}/qa
QA_FOLDER_ETL=/script/etl/wurzburg/reports
LOG_FOLDER_HOST=${PWD}/log
LOG_FOLDER_ETL=/script/etl/wurzburg/log

echo "Download questions for ETL"
curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/RunETLWurzburg/questions.json --output questions.json

echo "Pull ETL runner Docker image"
docker pull $REGISTRY/$REPOSITORY/$IMAGE:$TAG

echo "Create database schema 'wurzburg_final'"
docker exec -it postgres psql -U postgres -d OHDSI -c "CREATE SCHEMA IF NOT EXISTS wurzburg_final AUTHORIZATION ohdsi_admin;GRANT USAGE ON SCHEMA wurzburg_final TO ohdsi_app;GRANT SELECT ON ALL TABLES IN SCHEMA wurzburg_final TO ohdsi_app;GRANT USAGE ON SCHEMA wurzburg_final TO ohdsi_admin;GRANT ALL ON ALL TABLES IN SCHEMA wurzburg_final TO ohdsi_admin;"

touch etl-runner.env
echo "THERAPEUTIC_AREA=honeur" >> etl-runner.env
echo "REGISTRY=$REGISTRY" >> etl-runner.env
echo "ETL_IMAGE_NAME=etl-wurzburg/etl" >> etl-runner.env
echo "ETL_IMAGE_TAG=latest" >> etl-runner.env
echo "DATA_FOLDER_HOST=$DATA_FOLDER_HOST" >> etl-runner.env
echo "DATA_FOLDER=$DATA_FOLDER" >> etl-runner.env
echo "QA_FOLDER_HOST=$QA_FOLDER_HOST" >> etl-runner.env
echo "QA_FOLDER_ETL=$QA_FOLDER_ETL" >> etl-runner.env
echo "LOG_FOLDER_HOST=$LOG_FOLDER_HOST" >> etl-runner.env
echo "LOG_FOLDER=$LOG_FOLDER_ETL" >> etl-runner.env
echo "RUN_DQD=true" >> etl-runner.env
echo "CDM_VERSION=5.4" >> etl-runner.env
echo "SCRIPT_UUID=9719aeb1-84c4-49c5-a2a1-c6ea3af00305" >> etl-runner.env

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

rm -rf etl-runner.env

echo "ETL run finished"

echo "Set correct permissions on new database schema's"
docker exec -it postgres psql -U postgres -d OHDSI -c "REASSIGN OWNED BY feder8_admin TO ohdsi_admin;REASSIGN OWNED BY ohdsi_app_user TO ohdsi_app;grant usage on schema wurzburg_final to ohdsi_app;GRANT SELECT ON ALL TABLES IN SCHEMA wurzburg_final TO ohdsi_app;"
docker exec -it postgres psql -U postgres -d OHDSI -c "GRANT USAGE ON SCHEMA wurzburg_cdm TO ohdsi_app;GRANT SELECT ON ALL TABLES IN SCHEMA wurzburg_cdm TO ohdsi_app;GRANT USAGE ON SCHEMA wurzburg_src TO ohdsi_app;GRANT SELECT ON ALL TABLES IN SCHEMA wurzburg_src TO ohdsi_app;"
