#!/usr/bin/env bash
set -ex

REGISTRY=harbor.honeur.org
REPOSITORY=library
IMAGE=etl-runner
VERSION=1.1.4
TAG=$VERSION

DATA_FOLDER_HOST=${PWD}/data
LOG_FOLDER_HOST=${PWD}/log
QA_FOLDER_HOST=${PWD}/qa

echo "Pull ETL runner image"
docker pull $REGISTRY/$REPOSITORY/$IMAGE:$TAG

echo "Download ETL questions"
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/RunETLH12O/questions.json --output questions.json

touch etl-runner.env
echo "THERAPEUTIC_AREA=honeur" >> etl-runner.env
echo "REGISTRY=$REGISTRY" >> etl-runner.env
echo "LOG_LEVEL=INFO" >> etl-runner.env
echo "LOG_FOLDER_HOST=$LOG_FOLDER_HOST" >> etl-runner.env
echo "LOG_FOLDER=/var/log" >> etl-runner.env
echo "ETL_IMAGE_NAME=etl-h12o/etl" >> etl-runner.env
echo "ETL_IMAGE_TAG=current" >> etl-runner.env
echo "DATA_FOLDER_HOST=$DATA_FOLDER_HOST" >> etl-runner.env
echo "DATA_FOLDER=/etl/data" >> etl-runner.env
echo "SOURCE_DIR=/etl/data" >> etl-runner.env
echo "SOURCE_RELEASE_DATE=2024-11-24" >> etl-runner.env
echo "DATA_SHEET=Sheet1" >> etl-runner.env
echo "QA_FOLDER_HOST=$QA_FOLDER_HOST" >> etl-runner.env
echo "RUN_DQD=false" >> etl-runner.env
echo "SOURCE_SCHEMA=h12o_src" >> etl-runner.env
echo "TARGET_SCHEMA=omopcdm" >> etl-runner.env
echo "DELIMITER=\t" >> etl-runner.env
echo "ENCODING=utf-8" >> etl-runner.env
echo "FILE_TYPE=csv" >> etl-runner.env
echo "ACTIV=HDOC_INFOBANCO_ACTIV" >> etl-runner.env
echo "ADMINIST=HDOC_INFOBANCO_ADMINIST" >> etl-runner.env
echo "ALERT=HDOC_INFOBANCO_ALERT" >> etl-runner.env
echo "DEMOG=HDOC_INFOBANCO_DEMOG" >> etl-runner.env
echo "DIAGPROCED=HDOC_INFOBANCO_DIAGPROCED" >> etl-runner.env
echo "FARHOS=HDOC_INFOBANCO_FARHOS" >> etl-runner.env
echo "ONCOFAR=HDOC_INFOBANCO_ONCOFAR" >> etl-runner.env
echo "PRESC=HDOC_INFOBANCO_PRESC" >> etl-runner.env
echo "PROB=HDOC_INFOBANCO_PROB" >> etl-runner.env
echo "QUI=HDOC_INFOBANCO_QUI" >> etl-runner.env
echo "VISIT_ADM_URG=HDOC_INFOBANCO_VISIT_ADM_URG" >> etl-runner.env
echo "VISIT_AMB=HDOC_INFOBANCO_VISIT_AMB" >> etl-runner.env
#echo "DATA_SET=" >> etl-runner.env

echo "Run ETL"
docker run -it --rm --name etl-runner \
--env-file etl-runner.env \
-v /var/run/docker.sock:/var/run/docker.sock \
-v ${PWD}/questions.json:/script/questions.json \
--network feder8-net \
$REGISTRY/$REPOSITORY/$IMAGE:$TAG

echo "End of ETL run"
rm -rf etl-runner.env
