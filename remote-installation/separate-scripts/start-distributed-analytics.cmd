@echo off

SET VERSION=2.0.0
SET CURRENT_DIRECTORY=%CD%

set argumentCount=0
for %%x in (%*) do (
    set /A argumentCount+=1
    set "argVec[!argumentCount!]=%%~x"
)

if "%~1" NEQ "" (
    if "%argumentCount%" LSS "2" (
        echo Give all arguments or none to use the interactive script.
        EXIT 1
    ) else (
        SET "HONEUR_ANALYTICS_SHARED_FOLDER=%~1"
        SET "HONEUR_ANALYTICS_ORGANIZATION=%~2"
    )
    goto installation
)

SET /p HONEUR_ANALYTICS_SHARED_FOLDER="Enter the directory where Zeppelin will save the prepared distributed analytics data [%CURRENT_DIRECTORY%\distributed-analytics]: " || SET HONEUR_ANALYTICS_SHARED_FOLDER=%CURRENT_DIRECTORY%\distributed-analytics

SET /p HONEUR_ANALYTICS_ORGANIZATION="Enter your HONEUR organization [Janssen]: " || SET HONEUR_ANALYTICS_ORGANIZATION=Janssen

:installation
echo. 2>distributed-analytics.env

echo DISTRIBUTED_SERVICE_CLIENT_SCHEME=https> distributed-analytics.env
echo DISTRIBUTED_SERVICE_CLIENT_HOST=distributed-analytics.honeur.org>> distributed-analytics.env
echo DISTRIBUTED_SERVICE_CLIENT_PORT=443>> distributed-analytics.env
echo DISTRIBUTED_SERVICE_CLIENT_BIND=distributed-service>> distributed-analytics.env
echo DISTRIBUTED_SERVICE_CLIENT_API=api>> distributed-analytics.env
echo WEBAPI_CLIENT_SCHEME=http>> distributed-analytics.env
echo WEBAPI_CLIENT_HOST=webapi>> distributed-analytics.env
echo WEBAPI_CLIENT_PORT=8080>> distributed-analytics.env
echo WEBAPI_CLIENT_BIND=webapi>> distributed-analytics.env
echo WEBAPI_CLIENT_API=>> distributed-analytics.env
echo R_SERVER_CLIENT_SCHEME=http>> distributed-analytics.env
echo R_SERVER_CLIENT_HOST=distributed-analytics-r-server>> distributed-analytics.env
echo R_SERVER_CLIENT_PORT=8080>> distributed-analytics.env
echo R_SERVER_CLIENT_BIND=>> distributed-analytics.env
echo R_SERVER_CLIENT_API=>> distributed-analytics.env
echo HONEUR_ANALYTICS_ORGANIZATION=%HONEUR_ANALYTICS_ORGANIZATION%>> distributed-analytics.env

echo Stop and remove distributed analytics containers if exists
PowerShell -Command "docker stop $(docker ps --filter 'honeur-distributed-analytics-net' -q -a)" >nul 2>&1
PowerShell -Command "docker rm $(docker ps --filter 'honeur-distributed-analytics-net' -q -a)" >nul 2>&1

echo Create honeur-net network if it does not exists
docker network create --driver bridge honeur-net >nul 2>&1
echo Create honeur-distributed-analytics-net network if it does not exists
docker network create --driver bridge honeur-distributed-analytics-net >nul 2>&1

echo Pull honeur/distributed-analytics:r-server-%VERSION% from docker hub. This could take a while if not present on machine
docker pull honeur/distributed-analytics:r-server-%VERSION%
echo Pull honeur/distributed-analytics:remote-%VERSION% from docker hub. This could take a while if not present on machine
docker pull honeur/distributed-analytics:remote-%VERSION%

echo Run honeur/distributed-analytics:r-server-%VERSION% container. This could take a while...
docker run ^
--name "distributed-analytics-r-server" ^
--restart on-failure:5 ^
--security-opt no-new-privileges ^
-v "%HONEUR_ANALYTICS_SHARED_FOLDER%:/usr/local/src/datafiles" ^
-m "1g" ^
--cpus "2" ^
--pids-limit 100 ^
--cpu-shares 1024 ^
--ulimit nofile=1024:1024 ^
-d ^
honeur/distributed-analytics:r-server-%VERSION% >nul 2>&1

echo Connect distributed-analytics-r-server to honeur-net network
docker network connect honeur-net distributed-analytics-r-server >nul 2>&1
echo Connect distributed-analytics-r-server to honeur-distributed-analytics-net network
docker network connect honeur-distributed-analytics-net distributed-analytics-r-server >nul 2>&1

echo Run honeur/distributed-analytics:remote-%VERSION% container. This could take a while...
docker run ^
--name "distributed-analytics-remote" ^
--restart on-failure:5 ^
--security-opt no-new-privileges ^
--env-file distributed-analytics.env ^
-m "1g" ^
--cpus "2" ^
--read-only ^
--pids-limit 100 ^
--cpu-shares 1024 ^
--ulimit nofile=1024:1024 ^
-d ^
honeur/distributed-analytics:remote-%VERSION% >nul 2>&1

echo Connect distributed-analytics-remote to honeur-net network
docker network connect honeur-net distributed-analytics-remote >nul 2>&1
echo Connect distributed-analytics-remote to honeur-distributed-analytics-net network
docker network connect honeur-distributed-analytics-net distributed-analytics-remote >nul 2>&1

echo Clean up helper files
DEL /Q distributed-analytics.env

echo Done