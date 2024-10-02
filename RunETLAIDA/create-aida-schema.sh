#!/usr/bin/env bash
set -ex

VERSION=2.0.2
OMOP_CDM_VERSION="${OMOP_CDM_VERSION:-5.4}"
TAG=$OMOP_CDM_VERSION-$VERSION
SCHEMA=omopcdm_aida

touch omopcdm-initialize-schema.env

echo "DB_HOST=postgres" >> omopcdm-initialize-schema.env
echo "DB_PORT=5432" >> omopcdm-initialize-schema.env
echo "DB_DATABASE_NAME=OHDSI" >> omopcdm-initialize-schema.env
echo "DB_OMOPCDM_SCHEMA=$SCHEMA" >> omopcdm-initialize-schema.env
echo "FEDER8_ADMIN_USERNAME=feder8_admin" >> omopcdm-initialize-schema.env

docker run \
--rm \
--name omopcdm-initialize-schema \
-v shared:/var/lib/shared \
--env-file omopcdm-initialize-schema.env \
--network feder8-net \
harbor.honeur.org/honeur/postgres-omopcdm-initialize-schema:$TAG

rm -rf omopcdm-initialize-schema.env
