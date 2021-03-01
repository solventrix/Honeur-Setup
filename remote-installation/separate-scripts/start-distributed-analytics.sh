#!/usr/bin/env bash
set -e

VERSION_REMOTE=2.0.1
TAG_REMOTE=remote-$VERSION_REMOTE

VERSION_R_SERVER=2.0.2
TAG_R_SERVER=r-server-$VERSION_R_SERVER

CURRENT_DIRECTORY=$(pwd)

read -p "Enter the directory where Zeppelin will save the prepared distributed analytics data [$CURRENT_DIRECTORY/distributed-analytics]: " HONEUR_ANALYTICS_SHARED_FOLDER
HONEUR_ANALYTICS_SHARED_FOLDER=${HONEUR_ANALYTICS_SHARED_FOLDER:-$CURRENT_DIRECTORY/distributed-analytics}
read -p 'Enter your HONEUR organization [Janssen]: ' HONEUR_ANALYTICS_ORGANIZATION
HONEUR_ANALYTICS_ORGANIZATION=${HONEUR_ANALYTICS_ORGANIZATION:-Janssen}

touch distributed-analytics.env

echo "DISTRIBUTED_SERVICE_CLIENT_SCHEME=https" > distributed-analytics.env
echo "DISTRIBUTED_SERVICE_CLIENT_HOST=distributed-analytics.honeur.org" >> distributed-analytics.env
echo "DISTRIBUTED_SERVICE_CLIENT_PORT=443" >> distributed-analytics.env
echo "DISTRIBUTED_SERVICE_CLIENT_BIND=distributed-service" >> distributed-analytics.env
echo "DISTRIBUTED_SERVICE_CLIENT_API=api" >> distributed-analytics.env
echo "WEBAPI_CLIENT_SCHEME=http" >> distributed-analytics.env
echo "WEBAPI_CLIENT_HOST=webapi" >> distributed-analytics.env
echo "WEBAPI_CLIENT_PORT=8080" >> distributed-analytics.env
echo "WEBAPI_CLIENT_BIND=webapi" >> distributed-analytics.env
echo "WEBAPI_CLIENT_API=" >> distributed-analytics.env
echo "R_SERVER_CLIENT_SCHEME=http" >> distributed-analytics.env
echo "R_SERVER_CLIENT_HOST=distributed-analytics-r-server" >> distributed-analytics.env
echo "R_SERVER_CLIENT_PORT=8080" >> distributed-analytics.env
echo "R_SERVER_CLIENT_BIND=" >> distributed-analytics.env
echo "R_SERVER_CLIENT_API=" >> distributed-analytics.env
echo "HONEUR_ANALYTICS_ORGANIZATION=$HONEUR_ANALYTICS_ORGANIZATION" >> distributed-analytics.env

echo "Stop and remove distributed analytics containers if exists"
docker stop $(docker ps --filter 'network=honeur-distributed-analytics-net' -q -a) > /dev/null 2>&1 || true
docker rm $(docker ps --filter 'network=honeur-distributed-analytics-net' -q -a) > /dev/null 2>&1 || true

echo "Create honeur-net network if it does not exists"
docker network create --driver bridge honeur-net > /dev/null 2>&1 || true
echo "Create honeur-distributed-analytics-net network if it does not exists"
docker network create --driver bridge honeur-distributed-analytics-net > /dev/null 2>&1 || true

echo "Pull honeur/distributed-analytics:$TAG_R_SERVER from docker hub. This could take a while if not present on machine"
docker pull honeur/distributed-analytics:$TAG_R_SERVER
echo "Pull honeur/distributed-analytics:$TAG_REMOTE from docker hub. This could take a while if not present on machine"
docker pull honeur/distributed-analytics:$TAG_REMOTE

echo "Run honeur/distributed-analytics:$TAG_R_SERVER container. This could take a while..."
docker run \
--name "distributed-analytics-r-server" \
--restart on-failure:5 \
--security-opt no-new-privileges \
-v "$HONEUR_ANALYTICS_SHARED_FOLDER:/usr/local/src/datafiles" \
-m "1g" \
--cpus "2" \
--pids-limit 100 \
--cpu-shares 1024 \
--ulimit nofile=1024:1024 \
-d \
honeur/distributed-analytics:$TAG_R_SERVER > /dev/null 2>&1

echo "Connect distributed-analytics-r-server to honeur-net network"
docker network connect honeur-net distributed-analytics-r-server > /dev/null 2>&1
echo "Connect distributed-analytics-r-server to honeur-distributed-analytics-net network"
docker network connect honeur-distributed-analytics-net distributed-analytics-r-server > /dev/null 2>&1

echo "Run honeur/distributed-analytics:$TAG_REMOTE container. This could take a while..."
docker run \
--name "distributed-analytics-remote" \
--restart on-failure:5 \
--security-opt no-new-privileges \
--env-file distributed-analytics.env \
-m "1g" \
--cpus "2" \
--pids-limit 100 \
--cpu-shares 1024 \
--ulimit nofile=1024:1024 \
-d \
honeur/distributed-analytics:$TAG_REMOTE > /dev/null 2>&1

echo "Connect distributed-analytics-remote to honeur-net network"
docker network connect honeur-net distributed-analytics-remote > /dev/null 2>&1
echo "Connect distributed-analytics-remote to honeur-distributed-analytics-net network"
docker network connect honeur-distributed-analytics-net distributed-analytics-remote > /dev/null 2>&1

echo "Clean up helper files"
rm -rf distributed-analytics.env

echo "Done"