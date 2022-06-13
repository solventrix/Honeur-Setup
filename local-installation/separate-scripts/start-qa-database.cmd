@echo off
Setlocal EnableDelayedExpansion

set argumentCount=0
for %%x in (%*) do (
    set /A argumentCount+=1
    set "argVec[!argumentCount!]=%%~x"
)

if "%~1" NEQ "" (
    if %argumentCount% LSS 3 (
        echo Give all arguments or none to use the interactive script.
        EXIT 1
    )
    SET "FEDER8_THERAPEUTIC_AREA=%~1"
    SET "FEDER8_EMAIL_ADDRESS=%~2"
    SET "FEDER8_CLI_SECRET=%~3"
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
)
if "%FEDER8_THERAPEUTIC_AREA%" == "phederation" (
    SET FEDER8_THERAPEUTIC_AREA_DOMAIN=phederation.org
    SET FEDER8_THERAPEUTIC_AREA_URL=harbor-uat.!FEDER8_THERAPEUTIC_AREA_DOMAIN!
)
if "%FEDER8_THERAPEUTIC_AREA%" == "esfurn" (
    SET FEDER8_THERAPEUTIC_AREA_DOMAIN=esfurn.org
    SET FEDER8_THERAPEUTIC_AREA_URL=harbor-uat.!FEDER8_THERAPEUTIC_AREA_DOMAIN!
)
if "%FEDER8_THERAPEUTIC_AREA%" == "athena" (
    SET FEDER8_THERAPEUTIC_AREA_DOMAIN=athenafederation.org
    SET FEDER8_THERAPEUTIC_AREA_URL=harbor-uat.!FEDER8_THERAPEUTIC_AREA_DOMAIN!
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

:installation

for /f "usebackq delims=" %%I in (`powershell "\"%FEDER8_THERAPEUTIC_AREA%\".toUpper()"`) do set "FEDER8_THERAPEUTIC_AREA_UPPERCASE=%%~I"

if "%FEDER8_THERAPEUTIC_AREA%" == "honeur" (
    SET FEDER8_THERAPEUTIC_AREA_DOMAIN=honeur.org
    SET FEDER8_THERAPEUTIC_AREA_URL=harbor-uat.!FEDER8_THERAPEUTIC_AREA_DOMAIN!
)
if "%FEDER8_THERAPEUTIC_AREA%" == "phederation" (
    SET FEDER8_THERAPEUTIC_AREA_DOMAIN=phederation.org
    SET FEDER8_THERAPEUTIC_AREA_URL=harbor-uat.!FEDER8_THERAPEUTIC_AREA_DOMAIN!
)
if "%FEDER8_THERAPEUTIC_AREA%" == "esfurn" (
    SET FEDER8_THERAPEUTIC_AREA_DOMAIN=esfurn.org
    SET FEDER8_THERAPEUTIC_AREA_URL=harbor-uat.!FEDER8_THERAPEUTIC_AREA_DOMAIN!
)
if "%FEDER8_THERAPEUTIC_AREA%" == "athena" (
    SET FEDER8_THERAPEUTIC_AREA_DOMAIN=athenafederation.org
    SET FEDER8_THERAPEUTIC_AREA_URL=harbor-uat.!FEDER8_THERAPEUTIC_AREA_DOMAIN!
)

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/release/1.10.1/local-installation/separate-scripts/start-postgres.cmd --output start-postgres.cmd
SET FEDER8_SHARED_SECRETS_VOLUME_NAME=shared-qa
SET FEDER8_PGDATA_VOLUME_NAME=pgdata-qa
SET FEDER8_POSTGRES_CONTAINER_NAME=postgres-qa
SET FEDER8_RESTART_OTHER_COMPONENTS=false
SET FEDER8_CONTAINER_HOST_PORT=5445
CALL .\start-postgres.cmd "%FEDER8_THERAPEUTIC_AREA%" "%FEDER8_EMAIL_ADDRESS%" "%FEDER8_CLI_SECRET%" "%FEDER8_USER_PW%" "%FEDER8_ADMIN_USER_PW%"
DEL start-postgres.cmd

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/release/1.10.1/local-installation/separate-scripts/start-source-creation.cmd --output start-source-creation.cmd
SET FEDER8_SHARED_SECRETS_VOLUME_NAME=shared-qa
CALL .\start-source-creation.cmd "%FEDER8_THERAPEUTIC_AREA%" "%FEDER8_EMAIL_ADDRESS%" "%FEDER8_CLI_SECRET%" "postgres-qa" "%FEDER8_THERAPEUTIC_AREA_UPPERCASE% QA OMOP CDM" "2"
DEL start-source-creation.cmd

echo Done