@echo off
setlocal EnableDelayedExpansion

SET VERSION=2.0.2
SET TAG=%VERSION%

set argumentCount=0
for %%x in (%*) do (
    set /A argumentCount+=1
    set "argVec[!argumentCount!]=%%~x"
)

if "%~1" NEQ "" (
    if "%argumentCount%" LSS "3" (
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

:installation
echo. 2>nginx.env

echo HONEUR_THERAPEUTIC_AREA=%FEDER8_THERAPEUTIC_AREA%>> nginx.env
echo HONEUR_CHANGE_THERAPEUTIC_AREA_LIGHT_THEME_COLOR=%FEDER8_CHANGE_THERAPEUTIC_AREA_LIGHT_THEME_COLOR%>> nginx.env
echo HONEUR_CHANGE_THERAPEUTIC_AREA_DARK_THEME_COLOR=%FEDER8_CHANGE_THERAPEUTIC_AREA_DARK_THEME_COLOR%>> nginx.env

for /f "delims=" %%A in ('docker container inspect -f "{{.State.Running}}" webapi') do (
    if "%%A" == "true" (
        echo ATLAS_ENABLED=true>> nginx.env
        echo ATLAS_URL=/atlas>> nginx.env
    )
)

for /f "delims=" %%A in ('docker container inspect -f "{{.State.Running}}" zeppelin') do (
    if "%%A" == "true" (
        echo ZEPPELIN_ENABLED=true>> nginx.env
        echo ZEPPELIN_URL=/zeppelin/>> nginx.env
    )
)

for /f "delims=" %%A in ('docker container inspect -f "{{.State.Running}}" user-mgmt') do (
    if "%%A" == "true" (
        echo USER_MANAGEMENT_ENABLED=true>> nginx.env
        echo USER_MANAGEMENT_URL=/user-mgmt/>> nginx.env
    )
)

for /f "delims=" %%A in ('docker container inspect -f "{{.State.Running}}" %FEDER8_THERAPEUTIC_AREA%-studio') do (
    if "%%A" == "true" (
        echo HONEUR_STUDIO_ENABLED=true>> nginx.env
        echo HONEUR_THERAPEUTIC_AREA=%FEDER8_THERAPEUTIC_AREA%>> nginx.env
        echo RSTUDIO_URL=/%FEDER8_THERAPEUTIC_AREA%-studio/app/rstudio>> nginx.env
        echo VSCODE_URL=/%FEDER8_THERAPEUTIC_AREA%-studio/app/vscode>> nginx.env
        echo REPORTS_URL=/%FEDER8_THERAPEUTIC_AREA%-studio/app/reports>> nginx.env
        echo PERSONAL_URL=/%FEDER8_THERAPEUTIC_AREA%-studio/app/personal>> nginx.env
        echo DOCUMENTS_URL=/%FEDER8_THERAPEUTIC_AREA%-studio/app/documents>> nginx.env
    )
)

echo Stop and remove nginx container if exists
docker stop nginx > /dev/null >nul 2>&1
docker rm nginx > /dev/null >nul 2>&1

echo Create %FEDER8_THERAPEUTIC_AREA%-net network if it does not exists
docker network create --driver bridge %FEDER8_THERAPEUTIC_AREA%-net >nul 2>&1

echo Pull %FEDER8_THERAPEUTIC_AREA%/nginx:%TAG% from https://%FEDER8_THERAPEUTIC_AREA_URL%. This could take a while if not present on machine
docker login https://%FEDER8_THERAPEUTIC_AREA_URL% --username %FEDER8_EMAIL_ADDRESS% --password %FEDER8_CLI_SECRET%
docker pull %FEDER8_THERAPEUTIC_AREA_URL%/%FEDER8_THERAPEUTIC_AREA%/nginx:%TAG%

echo Run %FEDER8_THERAPEUTIC_AREA%/nginx:%TAG% container. This could take a while...
docker run ^
--name "nginx" ^
-p "80:8080" ^
--restart on-failure:5 ^
--security-opt no-new-privileges ^
--env-file nginx.env ^
--network %FEDER8_THERAPEUTIC_AREA%-net ^
-m "500m" ^
--cpus "1" ^
--pids-limit 100 ^
--cpu-shares 1024 ^
--ulimit nofile=1024:1024 ^
-d ^
%FEDER8_THERAPEUTIC_AREA_URL%/%FEDER8_THERAPEUTIC_AREA%/nginx:%TAG% >nul 2>&1

echo Clean up helper files
DEL /Q nginx.env

echo Done