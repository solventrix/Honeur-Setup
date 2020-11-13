#!/usr/bin/env bash
set -e

VERSION=2.0.0
CURRENT_DIRECTORY=$(pwd)

read -p "Enter the directory where Zeppelin will save the prepared distributed analytics data [$CURRENT_DIRECTORY/distributed-analytics]: " HONEUR_ANALYTICS_SHARED_FOLDER
HONEUR_ANALYTICS_SHARED_FOLDER=${HONEUR_ANALYTICS_SHARED_FOLDER:-$CURRENT_DIRECTORY/distributed-analytics}
read -p 'Enter your HONEUR organization [Janssen]: ' HONEUR_ANALYTICS_ORGANIZATION
HONEUR_ANALYTICS_ORGANIZATION=${HONEUR_ANALYTICS_ORGANIZATION:-Janssen}

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

docker stop $(docker ps --filter 'network=honeur-distributed-analytics-net' -q -a) > /dev/null 2>&1 || true
docker rm $(docker ps --filter 'network=honeur-distributed-analytics-net' -q -a) > /dev/null 2>&1 || true

docker network create --driver bridge honeur-net > /dev/null 2>&1 || true
docker network create --driver bridge honeur-distributed-analytics-net > /dev/null 2>&1 || true

docker run \
--name "distributed-analytics-r-server" \
--restart always \
--security-opt no-new-privileges \
-v "$HONEUR_ANALYTICS_SHARED_FOLDER:/usr/local/src/datafiles" \
-d \
honeur/distributed-analytics:r-server-$VERSION

docker network connect honeur-net distributed-analytics-r-server > /dev/null 2>&1 || true
docker network connect honeur-distributed-analytics-net distributed-analytics-r-server > /dev/null 2>&1 || true

docker run \
--name "distributed-analytics-remote" \
--restart always \
--security-opt no-new-privileges \
--env-file distributed-analytics.env \
-d \
honeur/distributed-analytics:remote-$VERSION

docker network connect honeur-net distributed-analytics-remote > /dev/null 2>&1 || true
docker network connect honeur-distributed-analytics-net distributed-analytics-remote > /dev/null 2>&1 || true

rm -rf distributed-analytics.env