@ECHO off

SET REGISTRY=harbor.honeur.org
SET REPOSITORY=distributed-analytics
SET IMAGE=analysis-table-generator
SET VERSION=1.1.7
SET TAG=%VERSION%

docker pull %REGISTRY%/%REPOSITORY%/%IMAGE%:%TAG%

docker run --rm --name analysis-table-generator --env THERAPEUTIC_AREA=HONEUR --env VERSION=%VERSION% -v %CD%/results:/script/results --network feder8-net %REGISTRY%/%REPOSITORY%/%IMAGE%:%TAG%
