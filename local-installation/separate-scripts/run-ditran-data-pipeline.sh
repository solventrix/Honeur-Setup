#!/usr/bin/env bash
set -ex

REGISTRY=harbor.honeur.org
REPOSITORY=honeur-restricted
IMAGE=disease-explorer-data-preparation
VERSION=1.1.3
TAG=$VERSION

echo "Analysis table is present in the following schema:"
ANALYSIS_TABLE_NAME="analysis_table"
ANALYSIS_TABLE_QUERY="SELECT table_schema FROM information_schema.tables WHERE table_name = '$ANALYSIS_TABLE_NAME'"
ANALYSIS_TABLE_SCHEMA=$(docker exec -it postgres psql -U postgres -d OHDSI -t -c "$ANALYSIS_TABLE_QUERY" | tr -d '[:space:]')

touch data-preparation.env
echo "DB_ANALYSIS_TABLE_SCHEMA=$ANALYSIS_TABLE_SCHEMA" >> data-preparation.env
echo "DB_ANALYSIS_TABLE_NAME=$ANALYSIS_TABLE_NAME" >> data-preparation.env

docker pull $REGISTRY/$REPOSITORY/$IMAGE:$TAG

docker run \
--rm \
--name disease-explorer-data-preparation \
-v disease-explorer-config:/pipeline/data \
--env-file data-preparation.env \
--network feder8-net \
$REGISTRY/$REPOSITORY/$IMAGE:$TAG

rm -rf data-preparation.env
