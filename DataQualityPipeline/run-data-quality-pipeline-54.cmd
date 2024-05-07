@ECHO off

SET REGISTRY=harbor.honeur.org
SET REPOSITORY=distributed-analytics
SET IMAGE=data-quality-pipeline
SET VERSION=1.8
SET TAG=%VERSION%
SET QA_FOLDER_HOST=%CD%/qa

echo "Docker login @ harbor.honeur.org"
docker login %REGISTRY%

docker pull %REGISTRY%/%REPOSITORY%/%IMAGE%:%TAG%

docker run --rm --name data-quality-pipeline --env REGISTRY=%REGISTRY% --env THERAPEUTIC_AREA=honeur --env INDICATION=mm --env QA_FOLDER_HOST=%QA_FOLDER_HOST% --env SCRIPT_UUID=5ebd99bd-4a1e-4d3e-93f0-706637951091 --env CDM_VERSION=5.4 -v /var/run/docker.sock:/var/run/docker.sock --network feder8-net %REGISTRY%/%REPOSITORY%/%IMAGE%:%TAG%