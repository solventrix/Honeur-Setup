#!/usr/bin/env bash
set -e

VERSION=2.0.0
TAG=HONEUR-9.6-omopcdm-5.3.1-webapi-2.7.1-$VERSION

echo "Stop and remove postgres container if exists"
docker stop postgres > /dev/null 2>&1 || true
docker rm postgres > /dev/null 2>&1 || true
echo "Removing existing helper volumes"
docker volume rm shared > /dev/null 2>&1 || true
echo "Create honeur-net network if it does not exists"
docker network create --driver bridge honeur-net > /dev/null 2>&1 || true

docker run \
--name "postgres" \
--restart always \
--security-opt no-new-privileges \
-p "5444:5432" \
-v "pgdata:/var/lib/postgresql/data" \
-v "shared:/var/lib/postgresql/envfileshared" \
-d \
honeur/postgres:$TAG > /dev/null 2>&1

echo "Connect postgres to honeur-net network"
docker network connect honeur-net postgres > /dev/null 2>&1 || true

echo "Done"