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

echo "Pull honeur/postgres:$TAG from docker hub. This could take a while if not present on machine..."
docker pull honeur/postgres:$TAG

echo "Creating helper volumes"
docker volume create shared > /dev/null 2>&1 || true
docker volume create pgdata > /dev/null 2>&1 || true

echo "Run honeur/postgres:$TAG container. This could take a while..."
docker run \
--name "postgres" \
--restart on-failure:5 \
--security-opt no-new-privileges \
-p "5444:5432" \
-v "pgdata:/var/lib/postgresql/data" \
-v "shared:/var/lib/postgresql/envfileshared" \
-m "2g" \
--cpus "2" \
--pids-limit 100 \
--cpu-shares 1024 \
--ulimit nofile=1024:1024 \
-d \
honeur/postgres:$TAG > /dev/null 2>&1

echo "Connect postgres to honeur-net network"
docker network connect honeur-net postgres > /dev/null 2>&1

echo "Done"
