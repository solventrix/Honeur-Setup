@echo off

SET VERSION_REMOTE=2.0.1
SET TAG_REMOTE=remote-%VERSION_REMOTE%

SET VERSION_R_SERVER=2.0.2
SET TAG_R_SERVER=r-server-%VERSION_R_SERVER%

SET CURRENT_DIRECTORY=%CD%

set argumentCount=0
for %%x in (%*) do (
    set /A argumentCount+=1
    set "argVec[!argumentCount!]=%%~x"
)

if "%~1" NEQ "" (
    if %argumentCount% LSS 5 (
        echo Give all arguments or none to use the interactive script.
        EXIT 1
    )
    SET "FEDER8_THERAPEUTIC_AREA=%~1"
    SET "FEDER8_EMAIL_ADDRESS=%~2"
    SET "FEDER8_CLI_SECRET=%~3"
    SET "FEDER8_ANALYTICS_SHARED_FOLDER=%~4"
    SET "FEDER8_ANALYTICS_ORGANIZATION=%~5"
    goto installation
)

SET /p FEDER8_THERAPEUTIC_AREA="Enter the Therapeutic Area of choice. Enter honeur/phederation/esfurn/athena [honeur]: " || SET FEDER8_THERAPEUTIC_AREA=honeur
:while-therapeutic-area-not-correct
if NOT "%FEDER8_THERAPEUTIC_AREA%" == "honeur" if NOT "%FEDER8_THERAPEUTIC_AREA%" == "phederation" if NOT "%FEDER8_THERAPEUTIC_AREA%" == "esfurn" if NOT "%FEDER8_THERAPEUTIC_AREA%" == "athena" if NOT "%FEDER8_THERAPEUTIC_AREA%" == "" (
   echo Enter "honeur", "phederation", "esfurn", "athena" or empty for default "honeur" value
   SET /p FEDER8_THERAPEUTIC_AREA="Enter the Therapeutic Area of choice. Enter honeur/phederation/esfurn/athena [honeur]: " || SET FEDER8_THERAPEUTIC_AREA=honeur
   goto :while-therapeutic-area-not-correct
)

if "%FEDER8_THERAPEUTIC_AREA%" == "honeur" (
    SET FEDER8_THERAPEUTIC_AREA_DOMAIN=honeur.org
    SET FEDER8_THERAPEUTIC_AREA_URL=harbor-uat.!FEDER8_THERAPEUTIC_AREA_DOMAIN!
    SET FEDER8_CHANGE_THERAPEUTIC_AREA_LIGHT_THEME_COLOR=#0794e0
    SET FEDER8_CHANGE_THERAPEUTIC_AREA_DARK_THEME_COLOR=#002562
)
if "%FEDER8_THERAPEUTIC_AREA%" == "phederation" (
    SET FEDER8_THERAPEUTIC_AREA_DOMAIN=phederation.org
    SET FEDER8_THERAPEUTIC_AREA_URL=harbor-uat.!FEDER8_THERAPEUTIC_AREA_DOMAIN!
    SET FEDER8_CHANGE_THERAPEUTIC_AREA_LIGHT_THEME_COLOR=#3590d5
    SET FEDER8_CHANGE_THERAPEUTIC_AREA_DARK_THEME_COLOR=#0741ad
)
if "%FEDER8_THERAPEUTIC_AREA%" == "esfurn" (
    SET FEDER8_THERAPEUTIC_AREA_DOMAIN=esfurn.org
    SET FEDER8_THERAPEUTIC_AREA_URL=harbor-uat.!FEDER8_THERAPEUTIC_AREA_DOMAIN!
    SET FEDER8_CHANGE_THERAPEUTIC_AREA_LIGHT_THEME_COLOR=#668772
    SET FEDER8_CHANGE_THERAPEUTIC_AREA_DARK_THEME_COLOR=#44594c
)
if "%FEDER8_THERAPEUTIC_AREA%" == "athena" (
    SET FEDER8_THERAPEUTIC_AREA_DOMAIN=athenafederation.org
    SET FEDER8_THERAPEUTIC_AREA_URL=harbor-uat.!FEDER8_THERAPEUTIC_AREA_DOMAIN!
    SET FEDER8_CHANGE_THERAPEUTIC_AREA_LIGHT_THEME_COLOR=#0794e0
    SET FEDER8_CHANGE_THERAPEUTIC_AREA_DARK_THEME_COLOR=#002562
)

SET /p FEDER8_EMAIL_ADDRESS="Enter email address used to login to https://portal-uat.%FEDER8_THERAPEUTIC_AREA_DOMAIN%: "
:while-email-address-not-correct
if "%FEDER8_EMAIL_ADDRESS%" == "" (
   echo Email address can not be empty
   SET /p FEDER8_EMAIL_ADDRESS="Enter email address used to login to https://portal-uat.%FEDER8_THERAPEUTIC_AREA_DOMAIN%: "
   goto :while-email-address-not-correct
)

echo Surf to https://%FEDER8_THERAPEUTIC_AREA_URL% and login using the button "LOGIN VIA OIDC PROVIDER". Then click your account name on the top right corner of the screen and click "User Profile". Copy the CLI secret by clicking the copy symbol next to the text field.
SET /p FEDER8_CLI_SECRET="Enter the CLI Secret: "
:while-cli-secret-not-correct
if "%FEDER8_CLI_SECRET%" == "" (
   echo Email address can not be empty
   SET /p FEDER8_CLI_SECRET="Enter email address used to login to https://portal-uat.%FEDER8_THERAPEUTIC_AREA_DOMAIN%: "
   goto :while-cli-secret-not-correct
)

SET /p FEDER8_ANALYTICS_SHARED_FOLDER="Enter the directory where Zeppelin will save the prepared distributed analytics data [%CURRENT_DIRECTORY%\distributed-analytics]: " || SET FEDER8_ANALYTICS_SHARED_FOLDER=%CURRENT_DIRECTORY%\distributed-analytics

SET /p FEDER8_ANALYTICS_ORGANIZATION="Enter your %FEDER8_THERAPEUTIC_AREA% organization [Janssen]: " || SET FEDER8_ANALYTICS_ORGANIZATION=Janssen

:installation
echo. 2>distributed-analytics.env

echo DISTRIBUTED_SERVICE_CLIENT_SCHEME=https> distributed-analytics.env
echo DISTRIBUTED_SERVICE_CLIENT_HOST=distributed-analytics-uat.%FEDER8_THERAPEUTIC_AREA%.org>> distributed-analytics.env
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
echo HONEUR_ANALYTICS_ORGANIZATION=%FEDER8_ANALYTICS_ORGANIZATION%>> distributed-analytics.env

echo Stop and remove distributed analytics containers if exists
PowerShell -Command "docker stop $(docker ps --filter '%FEDER8_THERAPEUTIC_AREA%-distributed-analytics-net' -q -a)" >nul 2>&1
PowerShell -Command "docker rm $(docker ps --filter '%FEDER8_THERAPEUTIC_AREA%-distributed-analytics-net' -q -a)" >nul 2>&1

echo Create %FEDER8_THERAPEUTIC_AREA%-net network if it does not exists
docker network create --driver bridge %FEDER8_THERAPEUTIC_AREA%-net >nul 2>&1
echo Create %FEDER8_THERAPEUTIC_AREA%-distributed-analytics-net network if it does not exists
docker network create --driver bridge %FEDER8_THERAPEUTIC_AREA%-distributed-analytics-net >nul 2>&1

echo Pull %FEDER8_THERAPEUTIC_AREA%/distributed-analytics:%TAG_R_SERVER% from https://%FEDER8_THERAPEUTIC_AREA_URL%. This could take a while if not present on machine
docker login https://%FEDER8_THERAPEUTIC_AREA_URL% --username %FEDER8_EMAIL_ADDRESS% --password %FEDER8_CLI_SECRET%
docker pull %FEDER8_THERAPEUTIC_AREA_URL%/%FEDER8_THERAPEUTIC_AREA%/distributed-analytics:%TAG_R_SERVER%
echo Pull %FEDER8_THERAPEUTIC_AREA%/distributed-analytics:%TAG_REMOTE% from https://%FEDER8_THERAPEUTIC_AREA_URL%. This could take a while if not present on machine
docker login https://%FEDER8_THERAPEUTIC_AREA_URL% --username %FEDER8_EMAIL_ADDRESS% --password %FEDER8_CLI_SECRET%
docker pull %FEDER8_THERAPEUTIC_AREA_URL%/%FEDER8_THERAPEUTIC_AREA%/distributed-analytics:%TAG_REMOTE%

echo Run %FEDER8_THERAPEUTIC_AREA%/distributed-analytics:%TAG_R_SERVER% container. This could take a while...
docker run ^
--name "distributed-analytics-r-server" ^
--restart on-failure:5 ^
--security-opt no-new-privileges ^
-v "%FEDER8_ANALYTICS_SHARED_FOLDER%:/usr/local/src/datafiles" ^
-m "1g" ^
--cpus "2" ^
--pids-limit 100 ^
--cpu-shares 1024 ^
--ulimit nofile=1024:1024 ^
-d ^
%FEDER8_THERAPEUTIC_AREA_URL%/%FEDER8_THERAPEUTIC_AREA%/distributed-analytics:%TAG_R_SERVER% >nul 2>&1

echo Connect distributed-analytics-r-server to %FEDER8_THERAPEUTIC_AREA%-net network
docker network connect %FEDER8_THERAPEUTIC_AREA%-net distributed-analytics-r-server >nul 2>&1
echo Connect distributed-analytics-r-server to %FEDER8_THERAPEUTIC_AREA%-distributed-analytics-net network
docker network connect %FEDER8_THERAPEUTIC_AREA%-distributed-analytics-net distributed-analytics-r-server >nul 2>&1

echo Run %FEDER8_THERAPEUTIC_AREA%/distributed-analytics:%TAG_REMOTE% container. This could take a while...
docker run ^
--name "distributed-analytics-remote" ^
--restart on-failure:5 ^
--security-opt no-new-privileges ^
--env-file distributed-analytics.env ^
-m "1g" ^
--cpus "2" ^
--pids-limit 100 ^
--cpu-shares 1024 ^
--ulimit nofile=1024:1024 ^
-d ^
%FEDER8_THERAPEUTIC_AREA_URL%/%FEDER8_THERAPEUTIC_AREA%/distributed-analytics:%TAG_REMOTE% >nul 2>&1

echo Connect distributed-analytics-remote to %FEDER8_THERAPEUTIC_AREA%-net network
docker network connect %FEDER8_THERAPEUTIC_AREA%-net distributed-analytics-remote >nul 2>&1
echo Connect distributed-analytics-remote to %FEDER8_THERAPEUTIC_AREA%-distributed-analytics-net network
docker network connect %FEDER8_THERAPEUTIC_AREA%-distributed-analytics-net distributed-analytics-remote >nul 2>&1

echo Clean up helper files
DEL /Q distributed-analytics.env

echo Done