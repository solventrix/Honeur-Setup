@ECHO off

SET REGISTRY=harbor.honeur.org
SET REPOSITORY=distributed-analytics
SET IMAGE=data-quality-pipeline
SET VERSION=1.9
SET TAG=%VERSION%
SET QA_FOLDER_HOST=%CD%/qa
SET LOG_FOLDER_HOST=%CD%/logs
SET LOG_FOLDER=/var/log/dqp

echo "Docker login @ harbor.honeur.org"
docker login %REGISTRY%

docker pull %REGISTRY%/%REPOSITORY%/%IMAGE%:%TAG%

docker run --rm --name data-quality-pipeline --env REGISTRY=%REGISTRY% --env THERAPEUTIC_AREA=honeur --env INDICATION=mm --env CDM_VERSION=5.4 --env QA_FOLDER_HOST=%QA_FOLDER_HOST% --env LOG_FOLDER_HOST=%LOG_FOLDER_HOST% --env LOG_FOLDER=%LOG_FOLDER% --env SCRIPT_UUID=30220b6a-a1c2-4e72-8ad3-f0873f53908b -v /var/run/docker.sock:/var/run/docker.sock -v %LOG_FOLDER_HOST%:%LOG_FOLDER% --network feder8-net %REGISTRY%/%REPOSITORY%/%IMAGE%:%TAG%