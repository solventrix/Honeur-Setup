@echo off

SET VERSION=2.0.0
SET TAG=HONEUR-9.6-omopcdm-5.3.1-webapi-2.7.1-%VERSION%

echo Stop and remove postgres container if exists
docker stop postgres >nul 2>&1
docker rm postgres >nul 2>&1

echo Removing existing helper volumes
docker volume rm shared >nul 2>&1

echo Create honeur-net network if it does not exists
docker network create --driver bridge honeur-net >nul 2>&1

echo Pull honeur/postgres:%TAG% from docker hub. This could take a while if not present on machine
docker pull honeur/postgres:%TAG%

echo Creating helper volumes
docker volume create shared >nul 2>&1
docker volume create pgdata >nul 2>&1

echo Run honeur/postgres:%TAG% container. This could take a while...
docker run ^
--name "postgres" ^
-p "5444:5432" ^
--restart on-failure:5 ^
--security-opt no-new-privileges ^
-v "pgdata:/var/lib/postgresql/data" ^
-v "shared:/var/lib/postgresql/envfileshared" ^
-m "200m" ^
--cpus ".5" ^
--pids-limit 100 ^
--cpu-shares 1024 ^
--ulimit nofile=1024:1024 ^
-d ^
honeur/postgres:%TAG% >nul 2>&1

echo Connect postgres to honeur-net network
docker network connect honeur-net postgres >nul 2>&1

echo Done