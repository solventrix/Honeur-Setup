#!/usr/bin/env bash
set -e

VERSION=2.0.0
TAG=$VERSION

touch nginx.env

if [ "$( docker container inspect -f '{{.State.Running}}' webapi )" == "true" ]; then
    echo "ATLAS_ENABLED=true" >> nginx.env
    echo "ATLAS_URL=/atlas" >> nginx.env
fi

if [ "$( docker container inspect -f '{{.State.Running}}' zeppelin )" == "true" ]; then
    echo "ZEPPELIN_ENABLED=true" >> nginx.env
    echo "ZEPPELIN_URL=/zeppelin/" >> nginx.env
fi

if [ "$( docker container inspect -f '{{.State.Running}}' user-mgmt )" == "true" ]; then
    echo "USER_MANAGEMENT_ENABLED=true" >> nginx.env
    echo "USER_MANAGEMENT_URL=/user-mgmt/" >> nginx.env
fi

if [ "$( docker container inspect -f '{{.State.Running}}' honeur-studio )" == "true" ]; then
    echo "HONEUR_STUDIO_ENABLED=true" >> nginx.env
    echo "RSTUDIO_URL=/honeur-studio/app/rstudio" >> nginx.env
    echo "VSCODE_URL=/honeur-studio/app/vscode" >> nginx.env
    echo "REPORTS_URL=/honeur-studio/app/reports" >> nginx.env
    echo "PERSONAL_URL=/honeur-studio/app/personal" >> nginx.env
    echo "DOCUMENTS_URL=/honeur-studio/app/documents" >> nginx.env
fi

docker stop nginx > /dev/null 2>&1 || true
docker rm nginx > /dev/null 2>&1 || true

docker network create --driver bridge honeur-net > /dev/null 2>&1 || true

docker pull honeur/nginx:$TAG

docker run \
--name "nginx" \
-p "80:80" \
--restart always \
--security-opt no-new-privileges \
--env-file nginx.env \
--network honeur-net \
-d \
honeur/nginx:$TAG

rm -rf nginx.env