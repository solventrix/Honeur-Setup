@ECHO off

SET REGISTRY=harbor.honeur.org
SET REPOSITORY=distributed-analytics
SET IMAGE=data-quality-pipeline
SET VERSION=1.7
SET TAG=%VERSION%
SET QA_FOLDER_HOST=%CD%/qa

echo "Docker login @ harbor.honeur.org"
docker login %REGISTRY%

docker pull %REGISTRY%/%REPOSITORY%/%IMAGE%:%TAG%

docker run --rm --name data-quality-pipeline --env REGISTRY=%REGISTRY% --env THERAPEUTIC_AREA=honeur --env INDICATION=mm --env QA_FOLDER_HOST=%QA_FOLDER_HOST% --env SCRIPT_UUID=0b77204e-bddf-4f40-a0de-9fe2d3fe8506 -v /var/run/docker.sock:/var/run/docker.sock --network feder8-net %REGISTRY%/%REPOSITORY%/%IMAGE%:%TAG%