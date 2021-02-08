#!/usr/bin/env bash
set -e

VERSION=2.0.1
TAG=PHEDERATION-9.6-omopcdm-5.3.1-webapi-2.7.1-$VERSION

HONEUR_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
HONEUR_ADMIN_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)

read -p "Enter password for phederation database user [$HONEUR_PASSWORD]: " HONEUR_PASSWORD
read -p "Enter password for phederation admin database user [$HONEUR_ADMIN_PASSWORD]: " HONEUR_ADMIN_PASSWORD

touch postgres.env

echo "HONEUR_USER_USERNAME=phederation" > postgres.env
echo "HONEUR_USER_PW=$HONEUR_PASSWORD" >> postgres.env
echo "HONEUR_ADMIN_USER_USERNAME=phederation_admin" >> postgres.env
echo "HONEUR_ADMIN_USER_PW=$HONEUR_ADMIN_PASSWORD" >> postgres.env

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
--env-file postgres.env \
-p "5444:5432" \
-v "pgdata:/var/lib/postgresql/data" \
-v "shared:/var/lib/postgresql/envfileshared" \
-m "800m" \
--cpus "2" \
--pids-limit 100 \
--cpu-shares 1024 \
--ulimit nofile=1024:1024 \
-d \
honeur/postgres:$TAG > /dev/null 2>&1

echo "Connect postgres to honeur-net network"
docker network connect honeur-net postgres > /dev/null 2>&1

echo "Clean up helper files"
rm -rf postgres.env

echo "Done"
