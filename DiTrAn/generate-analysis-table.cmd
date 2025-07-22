@ECHO off

SET REGISTRY=harbor.honeur.org
SET REPOSITORY=distributed-analytics
SET IMAGE=analysis-table-generator
SET VERSION=latest
SET TAG=%VERSION%

docker pull %REGISTRY%/%REPOSITORY%/%IMAGE%:%TAG%

docker run --rm --name analysis-table-generator --env THERAPEUTIC_AREA=HONEUR --env ANALYSIS_TABLE_SCHEMA=results --env ANALYSIS_TABLE_NAME=analysis_table --env ANALYSIS_TABLE_METADATA=analysis_table_metadata -v %CD%/results:/script/results --network feder8-net %REGISTRY%/%REPOSITORY%/%IMAGE%:%TAG%
