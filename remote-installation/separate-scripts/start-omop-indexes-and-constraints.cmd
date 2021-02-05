@echo off

SET VERSION=2.0.0
SET TAG=cdm-constraints-and-indexes-%VERSION%

echo. 2>omop-indexes-and-constraints.env

echo DB_HOST=postgres> omop-indexes-and-constraints.env

echo Stop and remove omop-indexes-and-constraints container if exists
docker stop omop-indexes-and-constraints > /dev/null >nul 2>&1
docker rm omop-indexes-and-constraints > /dev/null >nul 2>&1

echo Create honeur-net network if it does not exists
docker network create --driver bridge honeur-net >nul 2>&1

echo Pull honeur/postgres:%TAG% from docker hub. This could take a while if not present on machine
docker pull honeur/postgres:%TAG%

echo Run honeur/postgres:%TAG% container. This could take a while...
docker run ^
--name "omop-indexes-and-constraints" ^
--env-file omop-indexes-and-constraints.env ^
-v "shared:/var/lib/shared:ro" ^
--network honeur-net ^
honeur/postgres:%TAG% >nul 2>&1

echo Clean up helper files
DEL /Q omop-indexes-and-constraints.env

echo Done