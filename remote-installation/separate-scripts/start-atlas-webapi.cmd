@echo off
Setlocal EnableDelayedExpansion

SET VERSION=2.0.1
SET TAG=2.7.1-%VERSION%

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
    SET "FEDER8_HOST_MACHINE=%~4"
    SET "FEDER8_SECURITY_METHOD=%~5"
    SET "FEDER8_SECURITY_LDAP_URL=ldap://localhost:389"
    SET "FEDER8_SECURITY_LDAP_SYSTEM_USERNAME=username"
    SET "FEDER8_SECURITY_LDAP_SYSTEM_PASSWORD=password"
    SET "FEDER8_SECURITY_LDAP_BASE_DN=dc=example,dc=org"
    SET "FEDER8_SECURITY_LDAP_DN=cn={0},dc=example,dc=org"
    if "%~5" EQU "ldap" (
        if "%argumentCount%" LSS "10" (
            echo When LDAP is chosen as security option, please provide ldap properties.
            EXIT 1
        ) else (
            SET "FEDER8_SECURITY_LDAP_URL=%~6"
            SET "FEDER8_SECURITY_LDAP_SYSTEM_USERNAME=%~7"
            SET "FEDER8_SECURITY_LDAP_SYSTEM_PASSWORD=%~8"
            SET "FEDER8_SECURITY_LDAP_BASE_DN=%~9"
            shift
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

SET /p FEDER8_HOST_MACHINE="Enter the FQDN(Fully Qualified Domain Name eg. www.example.com) or public IP address(eg. 125.24.44.18) of the host machine. Use localhost to for testing [localhost]: " || SET FEDER8_HOST_MACHINE=localhost

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
if "%FEDER8_SECURITY_METHOD%" == "jdbc" (
    SET "FEDER8_SECURITY_LDAP_URL=ldap://localhost:389"
    SET "FEDER8_SECURITY_LDAP_SYSTEM_USERNAME=username"
    SET "FEDER8_SECURITY_LDAP_SYSTEM_PASSWORD=password"
    SET "FEDER8_SECURITY_LDAP_BASE_DN=dc=example,dc=org"
    SET "FEDER8_SECURITY_LDAP_DN=cn={0},dc=example,dc=org"
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

echo. 2>atlas-webapi.env

echo OHDSI_DATASOURCE_URL=jdbc:postgresql://postgres:5432/OHDSI> atlas-webapi.env
echo WEBAPI_URL=/webapi/>> atlas-webapi.env
echo JAVA_OPTS=-Xms512m -Xmx512m>> atlas-webapi.env
echo STORAGE_SERVER_BASE_URL=https://storage.%FEDER8_THERAPEUTIC_AREA_DOMAIN%>> atlas-webapi.env
if NOT "%FEDER8_SECURITY_METHOD%" == "none" (
    echo USER_AUTHENTICATION_ENABLED=true>> atlas-webapi.env
    echo LDAP_URL=%FEDER8_SECURITY_LDAP_URL%>> atlas-webapi.env
    echo LDAP_SYSTEM_USERNAME=%FEDER8_SECURITY_LDAP_SYSTEM_USERNAME%>> atlas-webapi.env
    echo LDAP_SYSTEM_PASSWORD=%FEDER8_SECURITY_LDAP_SYSTEM_PASSWORD%>> atlas-webapi.env
    echo LDAP_BASE_DN=%FEDER8_SECURITY_LDAP_BASE_DN%>> atlas-webapi.env
    echo LDAP_DN=%FEDER8_SECURITY_LDAP_DN%>> atlas-webapi.env
) else (
    echo USER_AUTHENTICATION_ENABLED=false>> atlas-webapi.env
)

echo Stop and remove webapi container if exists
docker stop webapi >nul 2>&1
docker rm webapi >nul 2>&1

if NOT "%FEDER8_SECURITY_METHOD%" == "none" (
    SET TAG=%TAG%-secure
) else (
    SET TAG=%TAG%-standard
)

echo Create %FEDER8_THERAPEUTIC_AREA%-net network if it does not exists
docker network create --driver bridge %FEDER8_THERAPEUTIC_AREA%-net >nul 2>&1

echo Pull honeur/webapi-atlas:%TAG% from docker hub. This could take a while if not present on machine
docker pull honeur/webapi-atlas:%TAG%

echo Run %FEDER8_THERAPEUTIC_AREA%/webapi-atlas:%TAG% container. This could take a while...
docker run ^
--name "webapi" ^
--restart on-failure:5 ^
--security-opt no-new-privileges ^
--env-file atlas-webapi.env ^
-v "shared:/var/lib/shared:ro" ^
-m "2g" ^
--cpus "2" ^
--pids-limit 150 ^
--cpu-shares 1024 ^
--ulimit nofile=1024:1024 ^
-d ^
%FEDER8_THERAPEUTIC_AREA_URL%/%FEDER8_THERAPEUTIC_AREA%/webapi-atlas:%TAG% >nul 2>&1

echo Connect webapi to %FEDER8_THERAPEUTIC_AREA%-net network
docker network connect %FEDER8_THERAPEUTIC_AREA%-net webapi >nul 2>&1

echo Clean up helper files
DEL /Q atlas-webapi.env

echo Done