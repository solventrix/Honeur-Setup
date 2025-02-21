@ECHO off

SET REGISTRY=harbor.honeur.org
SET REPOSITORY=study_36
SET IMAGE=landmark-study
SET VERSION=V7
SET TAG=%VERSION%

echo "Docker login @ %REGISTRY%"
docker login %REGISTRY%

echo "Pull Docker image"
docker pull %REGISTRY%/%REPOSITORY%/%IMAGE%:%TAG%

docker run --rm --name landmark-study --env THERAPEUTIC_AREA=HONEUR --env SCRIPT_UUID=9cc32497-4cd0-4882-9a6a-5714c869edcc -v "%CD%/results":/script/results  --network feder8-net %REGISTRY%/%REPOSITORY%/%IMAGE%:%TAG%

