#!/usr/bin/env bash
set -ex

docker exec -it postgres psql -U postgres -d OHDSI -c "ALTER TABLE results.analysis_table DROP COLUMN IF EXISTS cond_covid_fl CASCADE;ALTER TABLE results.analysis_table ADD COLUMN cond_covid_fl NUMERIC;"
docker exec -it postgres psql -U postgres -d OHDSI -c "update results.analysis_table set cond_covid_fl = 1 where person_id in ( SELECT distinct (person_id) FROM omopcdm.condition_occurrence co where condition_concept_id in (756061, 756039, 37311061));"
docker exec -it postgres psql -U postgres -d OHDSI -c "update results.analysis_table set cond_covid_fl = 0 where person_id not in ( SELECT distinct (person_id) FROM omopcdm.condition_occurrence co where condition_concept_id in (756061, 756039, 37311061));"

VERSION=1.1.6
TAG=$VERSION
REGISTRY=harbor.honeur.org
REPOSITORY=honeur-restricted
IMAGE=disease-explorer-data-preparation

docker login $REGISTRY

docker pull $REGISTRY/$REPOSITORY/$IMAGE:$TAG

docker run \
--rm \
--name disease-explorer-data-preparation \
-v disease-explorer-config:/pipeline/data \
--env DB_ANALYSIS_TABLE_NAME=analysis_table \
--network feder8-net \
$REGISTRY/$REPOSITORY/$IMAGE:$TAG
