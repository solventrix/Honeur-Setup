@echo off
Setlocal EnableDelayedExpansion

SET VERSION=2.0.0
SET TAG=0.8.2-%VERSION%

set argumentCount=0
for %%x in (%*) do (
    set /A argumentCount+=1
    set "argVec[!argumentCount!]=%%~x"
)

if "%~1" NEQ "" (
    if %argumentCount% LSS 7 (
        echo Give all arguments or none to use the interactive script.
        EXIT 1
    )
    SET "FEDER8_THERAPEUTIC_AREA=%~1"
    SET "FEDER8_EMAIL_ADDRESS=%~2"
    SET "FEDER8_CLI_SECRET=%~3"
    SET "FEDER8_ZEPPELIN_LOGS=%~4"
    SET "FEDER8_ZEPPELIN_NOTEBOOKS=%~5"
    SET "FEDER8_ANALYTICS_SHARED_FOLDER=%~6"
    SET "FEDER8_SECURITY_METHOD=%~7"
    if "%~7" EQU "ldap" (
        if %argumentCount% LSS 12 (
            echo When LDAP is chosen as security option, please provide ldap properties.
            EXIT 1
        ) else (
            SET "FEDER8_SECURITY_LDAP_URL=%~8"
            SET "FEDER8_SECURITY_LDAP_SYSTEM_USERNAME=%~9"
            shift
            shift
            shift
            SET "FEDER8_SECURITY_LDAP_SYSTEM_PASSWORD=%~7"
            SET "FEDER8_SECURITY_LDAP_BASE_DN=%~8"
            SET "FEDER8_SECURITY_LDAP_DN=%~9"
        )
    )
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
    SET FEDER8_CHANGE_THERAPEUTIC_AREA_LIGHT_THEME_COLOR=#0794e0
    SET FEDER8_CHANGE_THERAPEUTIC_AREA_DARK_THEME_COLOR=#002562
)
if "%FEDER8_THERAPEUTIC_AREA%" == "phederation" (
    SET FEDER8_THERAPEUTIC_AREA_DOMAIN=phederation.org
    SET FEDER8_THERAPEUTIC_AREA_URL=harbor.!FEDER8_THERAPEUTIC_AREA_DOMAIN!
    SET FEDER8_CHANGE_THERAPEUTIC_AREA_LIGHT_THEME_COLOR=#3590d5
    SET FEDER8_CHANGE_THERAPEUTIC_AREA_DARK_THEME_COLOR=#0741ad
)
if "%FEDER8_THERAPEUTIC_AREA%" == "esfurn" (
    SET FEDER8_THERAPEUTIC_AREA_DOMAIN=esfurn.org
    SET FEDER8_THERAPEUTIC_AREA_URL=harbor.!FEDER8_THERAPEUTIC_AREA_DOMAIN!
    SET FEDER8_CHANGE_THERAPEUTIC_AREA_LIGHT_THEME_COLOR=#668772
    SET FEDER8_CHANGE_THERAPEUTIC_AREA_DARK_THEME_COLOR=#44594c
)
if "%FEDER8_THERAPEUTIC_AREA%" == "athena" (
    SET FEDER8_THERAPEUTIC_AREA_DOMAIN=athenafederation.org
    SET FEDER8_THERAPEUTIC_AREA_URL=harbor.!FEDER8_THERAPEUTIC_AREA_DOMAIN!
    SET FEDER8_CHANGE_THERAPEUTIC_AREA_LIGHT_THEME_COLOR=#0794e0
    SET FEDER8_CHANGE_THERAPEUTIC_AREA_DARK_THEME_COLOR=#002562
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

SET CURRENT_DIRECTORY=%CD%
SET /p FEDER8_ZEPPELIN_LOGS="Enter the directory where the zeppelin logs will kept on the host machine [%CURRENT_DIRECTORY%\zeppelin\logs]: " || SET FEDER8_ZEPPELIN_LOGS=%CURRENT_DIRECTORY%\zeppelin\logs
SET /p FEDER8_ZEPPELIN_NOTEBOOKS="Enter the directory where the zeppelin notebooks will kept on the host machine [%CURRENT_DIRECTORY%\zeppelin\notebook]: " || SET FEDER8_ZEPPELIN_NOTEBOOKS=%CURRENT_DIRECTORY%\zeppelin\notebook
SET /p FEDER8_ANALYTICS_SHARED_FOLDER="Enter the directory where Zeppelin will save the prepared distributed analytics data [%CURRENT_DIRECTORY%\distributed-analytics]: " || SET FEDER8_ANALYTICS_SHARED_FOLDER=%CURRENT_DIRECTORY%\distributed-analytics

SET /p FEDER8_SECURITY_METHOD="Use jdbc users or LDAP or No for authentication? Enter jdbc/ldap/none. [none]: " || SET FEDER8_SECURITY_METHOD=none
:while-security-mode-not-correct
if NOT "%FEDER8_SECURITY_METHOD%" == "none" if NOT "%FEDER8_SECURITY_METHOD%" == "ldap" if NOT "%FEDER8_SECURITY_METHOD%" == "jdbc" (
   echo enter "none", "jdbc", "ldap" or empty for default "none" value
   SET /p FEDER8_SECURITY_METHOD="Use jdbc users or LDAP or No for authentication? Enter jdbc/ldap/none. [none]: " || SET FEDER8_SECURITY_METHOD=none
   goto :while-security-mode-not-correct
)

if "%FEDER8_SECURITY_METHOD%" == "ldap" (
    set /p FEDER8_SECURITY_LDAP_URL="security.ldap.url [ldap://ldap.forumsys.com:389]: " || SET "FEDER8_SECURITY_LDAP_URL=ldap://ldap.forumsys.com:389"
    set /p FEDER8_SECURITY_LDAP_SYSTEM_USERNAME="security.ldap.system.username [cn=read-only-admin,dc=example,dc=com]: " || SET "FEDER8_SECURITY_LDAP_SYSTEM_USERNAME=cn=read-only-admin,dc=example,dc=com"
    set /p FEDER8_SECURITY_LDAP_SYSTEM_PASSWORD="security.ldap.system.password [password]: " || SET FEDER8_SECURITY_LDAP_SYSTEM_PASSWORD=password
    set /p FEDER8_SECURITY_LDAP_BASE_DN="security.ldap.baseDn [dc=example,dc=com]: " || SET "FEDER8_SECURITY_LDAP_BASE_DN=dc=example,dc=com"
    set /p FEDER8_SECURITY_LDAP_DN="security.ldap.dn [uid={0},dc=example,dc=com]: " || SET "FEDER8_SECURITY_LDAP_DN=uid={0},dc=example,dc=com"
)

:installation

if "%FEDER8_THERAPEUTIC_AREA%" == "honeur" (
    SET FEDER8_THERAPEUTIC_AREA_DOMAIN=honeur.org
    SET FEDER8_THERAPEUTIC_AREA_URL=harbor.!FEDER8_THERAPEUTIC_AREA_DOMAIN!
    SET FEDER8_CHANGE_THERAPEUTIC_AREA_LIGHT_THEME_COLOR=#0794e0
    SET FEDER8_CHANGE_THERAPEUTIC_AREA_DARK_THEME_COLOR=#002562
)
if "%FEDER8_THERAPEUTIC_AREA%" == "phederation" (
    SET FEDER8_THERAPEUTIC_AREA_DOMAIN=phederation.org
    SET FEDER8_THERAPEUTIC_AREA_URL=harbor.!FEDER8_THERAPEUTIC_AREA_DOMAIN!
    SET FEDER8_CHANGE_THERAPEUTIC_AREA_LIGHT_THEME_COLOR=#3590d5
    SET FEDER8_CHANGE_THERAPEUTIC_AREA_DARK_THEME_COLOR=#0741ad
)
if "%FEDER8_THERAPEUTIC_AREA%" == "esfurn" (
    SET FEDER8_THERAPEUTIC_AREA_DOMAIN=esfurn.org
    SET FEDER8_THERAPEUTIC_AREA_URL=harbor.!FEDER8_THERAPEUTIC_AREA_DOMAIN!
    SET FEDER8_CHANGE_THERAPEUTIC_AREA_LIGHT_THEME_COLOR=#668772
    SET FEDER8_CHANGE_THERAPEUTIC_AREA_DARK_THEME_COLOR=#44594c
)
if "%FEDER8_THERAPEUTIC_AREA%" == "athena" (
    SET FEDER8_THERAPEUTIC_AREA_DOMAIN=athenafederation.org
    SET FEDER8_THERAPEUTIC_AREA_URL=harbor.!FEDER8_THERAPEUTIC_AREA_DOMAIN!
    SET FEDER8_CHANGE_THERAPEUTIC_AREA_LIGHT_THEME_COLOR=#0794e0
    SET FEDER8_CHANGE_THERAPEUTIC_AREA_DARK_THEME_COLOR=#002562
)

echo. 2>zeppelin.env

echo ZEPPELIN_NOTEBOOK_DIR=/notebook> zeppelin.env
echo ZEPPELIN_LOG_DIR=/logs>> zeppelin.env
if "%FEDER8_SECURITY_METHOD%" == "jdbc" (
    echo ZEPPELIN_SECURITY=%FEDER8_SECURITY_METHOD%>> zeppelin.env
    echo LDAP_URL=ldap://localhost:389>> zeppelin.env
    echo LDAP_BASE_DN=dc=example,dc=org>> zeppelin.env
    echo LDAP_DN=cn={0},dc=example,dc=org>> zeppelin.env
)
if "%FEDER8_SECURITY_METHOD%" == "ldap" (
    echo ZEPPELIN_SECURITY=%FEDER8_SECURITY_METHOD%>> zeppelin.env
    echo LDAP_URL=%FEDER8_SECURITY_LDAP_URL%>> zeppelin.env
    echo LDAP_BASE_DN=%FEDER8_SECURITY_LDAP_BASE_DN%>> zeppelin.env
    echo LDAP_DN=%FEDER8_SECURITY_LDAP_DN%>> zeppelin.env
)

echo Stop and remove zeppelin container if exists
docker stop zeppelin >nul 2>&1
docker rm zeppelin >nul 2>&1

echo Create %FEDER8_THERAPEUTIC_AREA%-net network if it does not exists
docker network create --driver bridge %FEDER8_THERAPEUTIC_AREA%-net >nul 2>&1

echo Pull %FEDER8_THERAPEUTIC_AREA%/zeppelin:%TAG% from https://%FEDER8_THERAPEUTIC_AREA_URL%. This could take a while if not present on machine
docker login https://%FEDER8_THERAPEUTIC_AREA_URL% --username %FEDER8_EMAIL_ADDRESS% --password %FEDER8_CLI_SECRET%
docker pull %FEDER8_THERAPEUTIC_AREA_URL%/%FEDER8_THERAPEUTIC_AREA%/zeppelin:%TAG%

echo Run %FEDER8_THERAPEUTIC_AREA%/zeppelin:%TAG% container. This could take a while...
docker run ^
--name "zeppelin" ^
--restart on-failure:5 ^
--security-opt no-new-privileges ^
--env-file zeppelin.env ^
-v "shared:/var/lib/shared:ro" ^
-v "%FEDER8_ANALYTICS_SHARED_FOLDER%:/usr/local/src/datafiles" ^
-v "%FEDER8_ZEPPELIN_LOGS%:/logs" ^
-v "%FEDER8_ZEPPELIN_NOTEBOOKS%:/notebook" ^
-m "4g" ^
--cpus "2" ^
--cpu-shares 1024 ^
--ulimit nofile=1024:1024 ^
-d ^
%FEDER8_THERAPEUTIC_AREA_URL%/%FEDER8_THERAPEUTIC_AREA%/zeppelin:%TAG% >nul 2>&1

echo Connect zeppelin to %FEDER8_THERAPEUTIC_AREA%-net network
docker network connect %FEDER8_THERAPEUTIC_AREA%-net zeppelin >nul 2>&1

echo Clean up helper files
DEL /Q zeppelin.env

echo Done