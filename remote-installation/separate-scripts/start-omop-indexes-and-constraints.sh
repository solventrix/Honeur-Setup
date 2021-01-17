#!/usr/bin/env bash
set -e

VERSION=2.0.0
TAG=omop-cdm-constraints-and-indexes-$VERSION

touch omop-indexes-and-constraints.env

echo "DB_HOST=postgres" > omop-indexes-and-constraints.env

echo "Stop and remove omop-indexes-and-constraints container if exists"
docker stop omop-indexes-and-constraints > /dev/null 2>&1 || true
docker rm omop-indexes-and-constraints > /dev/null 2>&1 || true

echo "Create honeur-net network if it does not exists"
docker network create --driver bridge honeur-net > /dev/null 2>&1 || true

echo "Pull honeur/postgres:$TAG from docker hub. This could take a while if not present on machine"
docker pull honeur/postgres:$TAG

echo "Run honeur/postgres:$TAG container. This could take a while..."
docker run \
--name "omop-indexes-and-constraints" \
--env-file omop-indexes-and-constraints.env \
-v "shared:/var/lib/shared:ro" \
--network honeur-net \
honeur/postgres:$TAG > /dev/null 2>&1

echo "Clean up helper files"
rm -rf omop-indexes-and-constraints.env

echo "Done"