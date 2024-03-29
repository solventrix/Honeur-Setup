@echo off
Setlocal EnableDelayedExpansion

SET VERSION=2.0.0
SET TAG=webapi-source-add-%VERSION%

set argumentCount=0
for %%x in (%*) do (
    set /A argumentCount+=1
    set "argVec[!argumentCount!]=%%~x"
)

if "%~1" NEQ "" (
    if %argumentCount% LSS 6 (
        echo Give all arguments or none to use the interactive script.
        EXIT 1
    )
    SET "FEDER8_THERAPEUTIC_AREA=%~1"
    SET "FEDER8_EMAIL_ADDRESS=%~2"
    SET "FEDER8_CLI_SECRET=%~3"
    SET "FEDER8_DATABASE_HOST=%~4"
    SET "FEDER8_SOURCE_NAME=%~5"
    SET "FEDER8_DAIMONS_PRIORITY=%~6"
    goto installation
)

SET /p FEDER8_THERAPEUTIC_AREA="Enter the Therapeutic Area of choice. Enter honeur/phederation/esfurn [honeur]: " || SET FEDER8_THERAPEUTIC_AREA=honeur
:while-therapeutic-area-not-correct
if NOT "%FEDER8_THERAPEUTIC_AREA%" == "honeur" if NOT "%FEDER8_THERAPEUTIC_AREA%" == "phederation" if NOT "%FEDER8_THERAPEUTIC_AREA%" == "esfurn" if NOT "%FEDER8_THERAPEUTIC_AREA%" == "" (
   echo Enter "honeur", "phederation", "esfurn" or empty for default "honeur" value
   SET /p FEDER8_THERAPEUTIC_AREA="Enter the Therapeutic Area of choice. Enter honeur/phederation/esfurn [honeur]: " || SET FEDER8_THERAPEUTIC_AREA=honeur
   goto :while-therapeutic-area-not-correct
)

for /f "usebackq delims=" %%I in (`powershell "\"%FEDER8_THERAPEUTIC_AREA%\".toUpper()"`) do set "FEDER8_THERAPEUTIC_AREA_UPPERCASE=%%~I"

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

SET /p FEDER8_EMAIL_ADDRESS="Enter email address used to login to https://portal.%FEDER8_THERAPEUTIC_AREA_DOMAIN%: "
:while-email-address-not-correct
if "%FEDER8_EMAIL_ADDRESS%" == "" (
   echo Email address can not be empty
   SET /p FEDER8_EMAIL_ADDRESS="Enter email address used to login to https://portal.%FEDER8_THERAPEUTIC_AREA_DOMAIN%: "
   goto :while-email-address-not-correct
)

echo Surf to https://%FEDER8_THERAPEUTIC_AREA_URL% and login using the button "LOGIN VIA OIDC PROVIDER". Then click your account name on the top right corner of the screen and click "User Profile". Copy the CLI secret by clicking the copy symbol next to the text field.
SET /p FEDER8_CLI_SECRET="Enter the CLI Secret: "
:while-cli-secret-not-correct
if "%FEDER8_CLI_SECRET%" == "" (
   echo Email address can not be empty
   SET /p FEDER8_CLI_SECRET="Enter email address used to login to https://portal.%FEDER8_THERAPEUTIC_AREA_DOMAIN%: "
   goto :while-cli-secret-not-correct
)

SET /p FEDER8_DATABASE_HOST="Enter the database host [postgres]: " || SET FEDER8_DATABASE_HOST=postgres

SET /p FEDER8_SOURCE_NAME="Enter the source name [%FEDER8_THERAPEUTIC_AREA_UPPERCASE% QA OMOP CDM]: " || SET FEDER8_SOURCE_NAME=%FEDER8_THERAPEUTIC_AREA_UPPERCASE% QA OMOP CDM

SET /p FEDER8_DAIMONS_PRIORITY="Enter the priority for the new source [2]: " || SET FEDER8_DAIMONS_PRIORITY=2

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

IF "%FEDER8_SHARED_SECRETS_VOLUME_NAME%"=="" (
    ECHO FEDER8_SHARED_SECRETS_VOLUME_NAME not set, using default shared volume for secrets.
    SET FEDER8_SHARED_SECRETS_VOLUME_NAME=shared
)

echo. 2>webapi-source-add.env

echo DB_HOST=%FEDER8_DATABASE_HOST%>> webapi-source-add.env
echo FEDER8_THERAPEUTIC_AREA=%FEDER8_THERAPEUTIC_AREA%>> webapi-source-add.env
echo FEDER8_DATABASE_HOST=%FEDER8_DATABASE_HOST%>> webapi-source-add.env
echo FEDER8_SOURCE_NAME=%FEDER8_SOURCE_NAME%>> webapi-source-add.env
echo FEDER8_DAIMONS_PRIORITY=%FEDER8_DAIMONS_PRIORITY%>> webapi-source-add.env

echo Stop and remove webapi-source-delete container if exists
docker stop webapi-source-add >nul 2>&1
docker rm webapi-source-add >nul 2>&1

echo Create feder8-net network if it does not exists
docker network create --driver bridge feder8-net >nul 2>&1

echo Pull %FEDER8_THERAPEUTIC_AREA%/postgres:%TAG% from https://%FEDER8_THERAPEUTIC_AREA_URL%. This could take a while if not present on machine
docker login https://%FEDER8_THERAPEUTIC_AREA_URL% --username %FEDER8_EMAIL_ADDRESS% --password %FEDER8_CLI_SECRET%
docker pull %FEDER8_THERAPEUTIC_AREA_URL%/%FEDER8_THERAPEUTIC_AREA%/postgres:%TAG%

echo Run %FEDER8_THERAPEUTIC_AREA%/postgres:%TAG% container. This could take a while...
docker run ^
--name "webapi-source-add" ^
--rm ^
-v %FEDER8_SHARED_SECRETS_VOLUME_NAME%:/var/lib/shared ^
--env-file webapi-source-add.env ^
--network feder8-net ^
%FEDER8_THERAPEUTIC_AREA_URL%/%FEDER8_THERAPEUTIC_AREA%/postgres:%TAG% >nul 2>&1

echo Clean up helper files
DEL /Q webapi-source-add.env

echo Done
EXIT /B 0
