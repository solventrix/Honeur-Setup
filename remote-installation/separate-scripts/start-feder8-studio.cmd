@echo off
Setlocal EnableDelayedExpansion

SET VERSION=2.0.3
SET TAG=%VERSION%

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
    for /f "usebackq delims=" %I in (`powershell "\"%FEDER8_THERAPEUTIC_AREA%\".toUpper()"`) do set "FEDER8_THERAPEUTIC_AREA_UPPERCASE=%~I"
    SET "FEDER8_EMAIL_ADDRESS=%~2"
    SET "FEDER8_CLI_SECRET=%~3"
    SET "FEDER8_HOST_MACHINE=%~4"
    SET "FEDER8_STUDIO_FOLDER=%~5"
    SET "FEDER8_ANALYTICS_SHARED_FOLDER=%~6"
    SET "FEDER8_SECURITY_METHOD=%~7"
    SET USERID=1000
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

SET CURRENT_DIRECTORY=%CD%
SET /p FEDER8_HOST_MACHINE="Enter the FQDN(Fully Qualified Domain Name eg. www.example.com) or public IP address(eg. 125.24.44.18) of the host machine. Use localhost to for testing [localhost]: " || SET FEDER8_HOST_MACHINE=localhost

SET /p FEDER8_STUDIO_FOLDER="Enter the directory where %FEDER8_THERAPEUTIC_AREA_UPPERCASE% Studio will store its data [%CURRENT_DIRECTORY%\%FEDER8_THERAPEUTIC_AREA%studio]: " || SET FEDER8_STUDIO_FOLDER=%CURRENT_DIRECTORY%\%FEDER8_THERAPEUTIC_AREA%studio

SET /p FEDER8_ANALYTICS_SHARED_FOLDER="Enter the directory where %FEDER8_THERAPEUTIC_AREA_UPPERCASE% Studio will save the prepared distributed analytics data [%CURRENT_DIRECTORY%\distributed-analytics]: " || SET FEDER8_ANALYTICS_SHARED_FOLDER=%CURRENT_DIRECTORY%\distributed-analytics

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

SET USERID=1000

:installation

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

echo. 2>honeur-studio.env

echo TAG=%TAG%> honeur-studio.env
echo APPLICATION_LOGS_TO_STDOUT=false>> honeur-studio.env
echo SITE_NAME=%FEDER8_THERAPEUTIC_AREA%studio>> honeur-studio.env
echo CONTENT_PATH=%FEDER8_STUDIO_FOLDER%>> honeur-studio.env
echo USERID=%USERID%>> honeur-studio.env
echo DOMAIN_NAME=%FEDER8_HOST_MACHINE%>> honeur-studio.env
echo HONEUR_DISTRIBUTED_ANALYTICS_DATA_FOLDER=%FEDER8_ANALYTICS_SHARED_FOLDER%>> honeur-studio.env
echo AUTHENTICATION_METHOD=%FEDER8_SECURITY_METHOD%>> honeur-studio.env
echo HONEUR_THERAPEUTIC_AREA=%FEDER8_THERAPEUTIC_AREA%>> honeur-studio.env
echo HONEUR_THERAPEUTIC_AREA_URL=%FEDER8_THERAPEUTIC_AREA_URL%>> honeur-studio.env
echo HONEUR_THERAPEUTIC_AREA_UPPERCASE=%FEDER8_THERAPEUTIC_AREA_UPPERCASE%>> honeur-studio.env
if "%FEDER8_SECURITY_METHOD%" == "jdbc" (
    echo DATASOURCE_DRIVER_CLASS_NAME=org.postgresql.Driver>> honeur-studio.env
    echo DATASOURCE_URL=jdbc:postgresql://postgres:5432/OHDSI?currentSchema=webapi>> honeur-studio.env
    echo WEBAPI_ADMIN_USERNAME=ohdsi_admin_user>> honeur-studio.env
)
if "%FEDER8_SECURITY_METHOD%" == "ldap" (
    echo HONEUR_STUDIO_LDAP_URL=%FEDER8_SECURITY_LDAP_URL%/%FEDER8_SECURITY_LDAP_BASE_DN%>> honeur-studio.env
    echo HONEUR_STUDIO_LDAP_DN=uid={0}>> honeur-studio.env
    echo HONEUR_STUDIO_LDAP_MANAGER_DN=%FEDER8_SECURITY_LDAP_SYSTEM_USERNAME%>> honeur-studio.env
    echo HONEUR_STUDIO_LDAP_MANAGER_PASSWORD=%FEDER8_SECURITY_LDAP_SYSTEM_PASSWORD%>> honeur-studio.env
)

echo. 2>honeur-studio-chronicle.env

echo SITE_NAME=%FEDER8_THERAPEUTIC_AREA%studio> honeur-studio-chronicle.env
echo USERID=%USERID%>> honeur-studio-chronicle.env
echo USER=%FEDER8_THERAPEUTIC_AREA%studio>> honeur-studio-chronicle.env

echo Stop and remove all %FEDER8_THERAPEUTIC_AREA%-studio containers if exists
PowerShell -Command "docker stop $(docker ps --filter 'network=%FEDER8_THERAPEUTIC_AREA%-studio-net' -q -a)" >nul 2>&1
PowerShell -Command "docker rm $(docker ps --filter 'network=%FEDER8_THERAPEUTIC_AREA%-studio-net' -q -a)" >nul 2>&1

echo Create %FEDER8_THERAPEUTIC_AREA%-net network if it does not exists
docker network create --driver bridge %FEDER8_THERAPEUTIC_AREA%-net >nul 2>&1
echo Create %FEDER8_THERAPEUTIC_AREA%-studio-frontend-net network if it does not exists
docker network create --driver bridge %FEDER8_THERAPEUTIC_AREA%-studio-frontend-net >nul 2>&1
echo Create %FEDER8_THERAPEUTIC_AREA%-studio-net network if it does not exists
docker network create --driver bridge %FEDER8_THERAPEUTIC_AREA%-studio-net >nul 2>&1

echo Pull %FEDER8_THERAPEUTIC_AREA%/%FEDER8_THERAPEUTIC_AREA%-studio:%TAG% from https://%FEDER8_THERAPEUTIC_AREA_URL%. This could take a while if not present on machine
docker login https://%FEDER8_THERAPEUTIC_AREA_URL% --username %FEDER8_EMAIL_ADDRESS% --password %FEDER8_CLI_SECRET%
docker pull %FEDER8_THERAPEUTIC_AREA_URL%/%FEDER8_THERAPEUTIC_AREA%/%FEDER8_THERAPEUTIC_AREA%-studio:%TAG%

echo Run %FEDER8_THERAPEUTIC_AREA%/%FEDER8_THERAPEUTIC_AREA%-studio:%TAG% container. This could take a while...
docker run ^
--name "%FEDER8_THERAPEUTIC_AREA%-studio-chronicle" ^
--restart on-failure:5 ^
--security-opt no-new-privileges ^
--env-file honeur-studio-chronicle.env ^
--hostname "cronicle" ^
-v "%FEDER8_STUDIO_FOLDER%:/home/%FEDER8_THERAPEUTIC_AREA%studio/__%FEDER8_THERAPEUTIC_AREA_UPPERCASE%Studio__:z" ^
-v "r_libraries:/r-libs" ^
-v "py_environment:/conda" ^
-v "cronicle_data:/opt/cronicle" ^
-v "pwsh_modules:/home/%FEDER8_THERAPEUTIC_AREA%studio/.local/share/powershell/Modules" ^
-m "500m" ^
--cpus "1" ^
--pids-limit 100 ^
--cpu-shares 1024 ^
--ulimit nofile=1024:1024 ^
-d ^
%FEDER8_THERAPEUTIC_AREA_URL%/%FEDER8_THERAPEUTIC_AREA%/%FEDER8_THERAPEUTIC_AREA%-studio:%TAG% cronicle >nul 2>&1

echo Connect %FEDER8_THERAPEUTIC_AREA%-studio-chronicle to %FEDER8_THERAPEUTIC_AREA%-net network
docker network connect %FEDER8_THERAPEUTIC_AREA%-net %FEDER8_THERAPEUTIC_AREA%-studio-chronicle >nul 2>&1
echo Connect %FEDER8_THERAPEUTIC_AREA%-studio-chronicle to %FEDER8_THERAPEUTIC_AREA%-studio-frontend-net network
docker network connect %FEDER8_THERAPEUTIC_AREA%-studio-frontend-net %FEDER8_THERAPEUTIC_AREA%-studio-chronicle >nul 2>&1
echo Connect %FEDER8_THERAPEUTIC_AREA%-studio-chronicle to %FEDER8_THERAPEUTIC_AREA%-studio-net network
docker network connect %FEDER8_THERAPEUTIC_AREA%-studio-net %FEDER8_THERAPEUTIC_AREA%-studio-chronicle >nul 2>&1

echo Run %FEDER8_THERAPEUTIC_AREA%/%FEDER8_THERAPEUTIC_AREA%-studio:%TAG% container. This could take a while...
docker run ^
--name "%FEDER8_THERAPEUTIC_AREA%-studio" ^
--restart on-failure:5 ^
--security-opt no-new-privileges ^
--env-file honeur-studio.env ^
-v "shared:/var/lib/shared:ro" ^
-v "/var/run/docker.sock:/var/run/docker.sock" ^
-m "1g" ^
--cpus "2" ^
--pids-limit 100 ^
--cpu-shares 1024 ^
--ulimit nofile=1024:1024 ^
-d ^
%FEDER8_THERAPEUTIC_AREA_URL%/%FEDER8_THERAPEUTIC_AREA%/%FEDER8_THERAPEUTIC_AREA%-studio:%TAG% shinyproxy >nul 2>&1

echo Connect %FEDER8_THERAPEUTIC_AREA%-studio to %FEDER8_THERAPEUTIC_AREA%-net network
docker network connect %FEDER8_THERAPEUTIC_AREA%-net %FEDER8_THERAPEUTIC_AREA%-studio >nul 2>&1
echo Connect %FEDER8_THERAPEUTIC_AREA%-studio to %FEDER8_THERAPEUTIC_AREA%-studio-frontend-net network
docker network connect %FEDER8_THERAPEUTIC_AREA%-studio-frontend-net %FEDER8_THERAPEUTIC_AREA%-studio >nul 2>&1
echo Connect %FEDER8_THERAPEUTIC_AREA%-studio to %FEDER8_THERAPEUTIC_AREA%-studio-net network
docker network connect %FEDER8_THERAPEUTIC_AREA%-studio-net %FEDER8_THERAPEUTIC_AREA%-studio >nul 2>&1

echo Clean up helper files
DEL /Q honeur-studio.env
DEL /Q honeur-studio-chronicle.env

echo Done
