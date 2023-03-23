#!/usr/bin/env bash
set -ex

VERSION=1.0.0
TAG=$VERSION
REGISTRY=harbor.honeur.org
REPOSITORY=etl-cllear

LOG_FOLDER=${PWD}/logs

read -p "Input Data folder [${PWD}/data]: " data_folder
data_folder=${data_folder:-${PWD}/data}
read -p "DB username [honeur_admin]: " db_username
db_username=${db_username:-honeur_admin}
read -p "DB password [honeur_admin]: " db_password
db_password=${db_password:-honeur_admin}

docker pull $REGISTRY/$REPOSITORY/etl:$TAG

mkdir -p $LOG_FOLDER

touch etl-cllear.env
echo "THERAPEUTIC_AREA=honeur" >> etl-cllear.env
echo "REGISTRY=$REGISTRY" >> etl-cllear.env
echo "LOG_LEVEL=INFO" >> etl-cllear.env
echo "LOG_FOLDER=$LOG_FOLDER" >> etl-cllear.env
echo "DB_SERVER=postgres" >> etl-cllear.env
echo "DB_PORT=5432" >> etl-cllear.env
echo "DB_NAME=OHDSI" >> etl-cllear.env
echo "DB_USERNAME=$db_username" >> etl-cllear.env
echo "DB_PASSWORD=$db_password" >> etl-cllear.env
echo "DATA_FOLDER=/etl/data" >> etl-cllear.env

docker run \
--rm \
--name etl-cllear \
--env-file etl-cllear.env \
-v "$data_folder":/etl/data \
-v "$LOG_FOLDER":/etl/logs \
--network feder8-net \
$REGISTRY/$REPOSITORY/etl:$TAG

rm -rf etl-cllear.env
