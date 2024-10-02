#!/usr/bin/env bash
set -ex

VERSION="${VERSION:-2.0.3}"
TAG=$VERSION
SCHEMA=results_aida

touch results-initialize-schema.env

echo "DB_HOST=postgres" >> results-initialize-schema.env
echo "DB_PORT=5432" >> results-initialize-schema.env
echo "DB_DATABASE_NAME=OHDSI" >> results-initialize-schema.env
echo "DB_RESULTS_SCHEMA=$SCHEMA" >> results-initialize-schema.env
echo "FEDER8_ADMIN_USERNAME=feder8_admin" >> results-initialize-schema.env

docker run \
--rm \
--name results-initialize-schema \
-v shared:/var/lib/shared \
--env-file results-initialize-schema.env \
--network feder8-net \
harbor.honeur.org/honeur/postgres-results-initialize-schema:$TAG

rm -rf results-initialize-schema.env
