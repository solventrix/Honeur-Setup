#!/usr/bin/env bash
set -e

TAG="HONEUR-9.6-omopcdm-5.3.1-webapi-2.7.1-2.0.0"

docker stop postgres > /dev/null 2>&1 || true
docker rm postgres > /dev/null 2>&1 || true
docker volume rm shared > /dev/null 2>&1 || true
docker network create --driver bridge honeur-net > /dev/null 2>&1 || true

docker run \
--name "postgres" \
--restart always \
--security-opt no-new-privileges \
-p "5444:5432" \
-v "pgdata:/var/lib/postgresql/data" \
-v "shared:/var/lib/postgresql/envfileshared" \
-d \
honeur/postgres:$TAG

docker network connect honeur-net postgres > /dev/null 2>&1 || true