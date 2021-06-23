@echo off
Setlocal EnableDelayedExpansion

SET VERSION=2.0.2
SET TAG=9.6-omopcdm-5.3.1-webapi-2.7.1-%VERSION%

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
    SET "FEDER8_USER_PW=%~4"
    SET "FEDER8_ADMIN_USER_PW=%~5"
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
    SET FEDER8_THERAPEUTIC_AREA_URL=harbor.!FEDER8_THERAPEUTIC_AREA_DOMAIN!
)
if "%FEDER8_THERAPEUTIC_AREA%" == "phederation" (
    SET FEDER8_THERAPEUTIC_AREA_DOMAIN=phederation.org
    SET FEDER8_THERAPEUTIC_AREA_URL=harbor.!FEDER8_THERAPEUTIC_AREA_DOMAIN!
)
if "%FEDER8_THERAPEUTIC_AREA%" == "esfurn" (
    SET FEDER8_THERAPEUTIC_AREA_DOMAIN=esfurn.org
    SET FEDER8_THERAPEUTIC_AREA_URL=harbor.!FEDER8_THERAPEUTIC_AREA_DOMAIN!
)
if "%FEDER8_THERAPEUTIC_AREA%" == "athena" (
    SET FEDER8_THERAPEUTIC_AREA_DOMAIN=athenafederation.org
    SET FEDER8_THERAPEUTIC_AREA_URL=harbor.!FEDER8_THERAPEUTIC_AREA_DOMAIN!
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

CALL :generate-random-password FEDER8_USER_PW
CALL :generate-random-password FEDER8_ADMIN_USER_PW

SET /p FEDER8_USER_PW="Enter password for %FEDER8_THERAPEUTIC_AREA% database user [%FEDER8_USER_PW%]: " || SET FEDER8_USER_PW=%FEDER8_USER_PW%
SET /p FEDER8_ADMIN_USER_PW="Enter password for %FEDER8_THERAPEUTIC_AREA%_admin database user [%FEDER8_ADMIN_USER_PW%]: " || SET FEDER8_ADMIN_USER_PW=%FEDER8_ADMIN_USER_PW%

:installation

if "%FEDER8_THERAPEUTIC_AREA%" == "honeur" (
    SET FEDER8_THERAPEUTIC_AREA_DOMAIN=honeur.org
    SET FEDER8_THERAPEUTIC_AREA_URL=harbor.!FEDER8_THERAPEUTIC_AREA_DOMAIN!
)
if "%FEDER8_THERAPEUTIC_AREA%" == "phederation" (
    SET FEDER8_THERAPEUTIC_AREA_DOMAIN=phederation.org
    SET FEDER8_THERAPEUTIC_AREA_URL=harbor.!FEDER8_THERAPEUTIC_AREA_DOMAIN!
)
if "%FEDER8_THERAPEUTIC_AREA%" == "esfurn" (
    SET FEDER8_THERAPEUTIC_AREA_DOMAIN=esfurn.org
    SET FEDER8_THERAPEUTIC_AREA_URL=harbor.!FEDER8_THERAPEUTIC_AREA_DOMAIN!
)
if "%FEDER8_THERAPEUTIC_AREA%" == "athena" (
    SET FEDER8_THERAPEUTIC_AREA_DOMAIN=athenafederation.org
    SET FEDER8_THERAPEUTIC_AREA_URL=harbor.!FEDER8_THERAPEUTIC_AREA_DOMAIN!
)

IF "%FEDER8_SHARED_SECRETS_VOLUME_NAME%"=="" (
    ECHO FEDER8_SHARED_SECRETS_VOLUME_NAME not set, using default shared volume for secrets.
    SET FEDER8_SHARED_SECRETS_VOLUME_NAME=shared
)
IF "%FEDER8_PGDATA_VOLUME_NAME%"=="" SET FEDER8_PGDATA_VOLUME_NAME=pgdata
IF "%FEDER8_POSTGRES_CONTAINER_NAME%"=="" SET FEDER8_POSTGRES_CONTAINER_NAME=postgres
IF "%FEDER8_RESTART_OTHER_COMPONENTS%"=="" SET FEDER8_RESTART_OTHER_COMPONENTS=true
IF "%FEDER8_CONTAINER_HOST_PORT%"=="" SET FEDER8_CONTAINER_HOST_PORT=5444

echo This script will install version 2.0.1 of the %FEDER8_THERAPEUTIC_AREA% database. All %FEDER8_THERAPEUTIC_AREA% docker containers will be restarted after running this script.

echo. 2>postgres.env

echo HONEUR_USER_USERNAME=%FEDER8_THERAPEUTIC_AREA%> postgres.env
echo HONEUR_USER_PW=%FEDER8_USER_PW%>> postgres.env
echo HONEUR_ADMIN_USER_USERNAME=%FEDER8_THERAPEUTIC_AREA%_admin>> postgres.env
echo HONEUR_ADMIN_USER_PW=%FEDER8_ADMIN_USER_PW%>> postgres.env

echo Stop and remove %FEDER8_POSTGRES_CONTAINER_NAME% container if exists
docker stop %FEDER8_POSTGRES_CONTAINER_NAME% >nul 2>&1
docker rm %FEDER8_POSTGRES_CONTAINER_NAME% >nul 2>&1

echo Removing existing helper volumes
docker volume rm %FEDER8_SHARED_SECRETS_VOLUME_NAME% >nul 2>&1

echo Create %FEDER8_THERAPEUTIC_AREA%-net network if it does not exists
docker network create --driver bridge %FEDER8_THERAPEUTIC_AREA%-net >nul 2>&1

echo Pull %FEDER8_THERAPEUTIC_AREA%/postgres:%TAG% from https://%FEDER8_THERAPEUTIC_AREA_URL%. This could take a while if not present on machine
docker login https://%FEDER8_THERAPEUTIC_AREA_URL% --username %FEDER8_EMAIL_ADDRESS% --password %FEDER8_CLI_SECRET%
docker pull %FEDER8_THERAPEUTIC_AREA_URL%/%FEDER8_THERAPEUTIC_AREA%/postgres:%TAG%

echo Creating helper volumes
docker volume create %FEDER8_SHARED_SECRETS_VOLUME_NAME% >nul 2>&1
docker volume create %FEDER8_PGDATA_VOLUME_NAME% >nul 2>&1

echo Run %FEDER8_THERAPEUTIC_AREA%/postgres:%TAG% container. This could take a while...
docker run ^
--name "%FEDER8_POSTGRES_CONTAINER_NAME%" ^
-p "%FEDER8_CONTAINER_HOST_PORT%:5432" ^
--env-file postgres.env ^
--restart on-failure:5 ^
--security-opt no-new-privileges ^
-v "%FEDER8_PGDATA_VOLUME_NAME%:/var/lib/postgresql/data" ^
-v "%FEDER8_SHARED_SECRETS_VOLUME_NAME%:/var/lib/postgresql/envfileshared" ^
-m "2g" ^
--cpus "2" ^
--pids-limit 100 ^
--cpu-shares 1024 ^
--ulimit nofile=1024:1024 ^
-d ^
%FEDER8_THERAPEUTIC_AREA_URL%/%FEDER8_THERAPEUTIC_AREA%/postgres:%TAG% >nul 2>&1

echo Connect %FEDER8_POSTGRES_CONTAINER_NAME% to %FEDER8_THERAPEUTIC_AREA%-net network
docker network connect %FEDER8_THERAPEUTIC_AREA%-net %FEDER8_POSTGRES_CONTAINER_NAME% >nul 2>&1

echo Clean up helper files
DEL /Q postgres.env

echo Done

IF "%FEDER8_RESTART_OTHER_COMPONENTS%"=="true" (
    echo Restarting %FEDER8_THERAPEUTIC_AREA% Components
    docker restart webapi >nul 2>&1
    docker restart user-mgmt >nul 2>&1
    docker restart zeppelin >nul 2>&1
    docker restart %FEDER8_THERAPEUTIC_AREA%-studio >nul 2>&1
    docker restart %FEDER8_THERAPEUTIC_AREA%-studio-chronicle >nul 2>&1
)

EXIT /B 0

:generate-random-password
@echo off
Setlocal EnableDelayedExpansion
Set _RNDLength=16
Set _Alphanumeric=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789
Set _Str=%_Alphanumeric%987654321
:_LenLoop
IF NOT "%_Str:~18%"=="" SET _Str=%_Str:~9%& SET /A _Len+=9& GOTO :_LenLoop
SET _tmp=%_Str:~9,1%
SET /A _Len=_Len+_tmp
Set _count=0
SET _RndAlphaNum=
:_loop
Set /a _count+=1
SET _RND=%Random%
Set /A _RND=_RND%%%_Len%
SET _RndAlphaNum=!_RndAlphaNum!!_Alphanumeric:~%_RND%,1!
If !_count! lss %_RNDLength% goto _loop
ENDLOCAL & SET %~1=%_RndAlphaNum%
EXIT /B 0