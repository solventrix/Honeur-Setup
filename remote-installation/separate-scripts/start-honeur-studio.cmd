@echo off

SET VERSION=2.0.2
SET TAG=%VERSION%

set argumentCount=0
for %%x in (%*) do (
    set /A argumentCount+=1
    set "argVec[!argumentCount!]=%%~x"
)

if "%~1" NEQ "" (
    if "%argumentCount%" LSS "4" (
        echo Give all arguments or none to use the interactive script.
        EXIT 1
    )
    SET "HONEUR_HOST_MACHINE=%~1"
    SET "HONEUR_HONEUR_STUDIO_FOLDER=%~2"
    SET "HONEUR_ANALYTICS_SHARED_FOLDER=%~3"
    SET "HONEUR_SECURITY_METHOD=%~3"
    SET USERID=1000
    if "%~3" EQU "ldap" (
        if "%argumentCount%" LSS "9" (
            echo When LDAP is chosen as security option, please provide ldap properties.
            EXIT 1
        ) else (
            SET "HONEUR_SECURITY_LDAP_URL=%~4"
            SET "HONEUR_SECURITY_LDAP_SYSTEM_USERNAME=%~5"
            SET "HONEUR_SECURITY_LDAP_SYSTEM_PASSWORD=%~6"
            SET "HONEUR_SECURITY_LDAP_BASE_DN=%~7"
            SET "HONEUR_SECURITY_LDAP_DN=%~8"
        )
    )
    goto installation
)

SET CURRENT_DIRECTORY=%CD%
SET /p HONEUR_HOST_MACHINE="Enter the FQDN(Fully Qualified Domain Name eg. www.example.com) or public IP address(eg. 125.24.44.18) of the host machine. Use localhost to for testing [localhost]: " || SET HONEUR_HOST_MACHINE=localhost

SET /p HONEUR_HONEUR_STUDIO_FOLDER="Enter the directory where HONEUR Studio will store its data [%CURRENT_DIRECTORY%\honeurstudio]: " || SET HONEUR_HONEUR_STUDIO_FOLDER=%CURRENT_DIRECTORY%\honeurstudio

SET /p HONEUR_ANALYTICS_SHARED_FOLDER="Enter the directory where HONEUR Studio will save the prepared distributed analytics data [%CURRENT_DIRECTORY%\distributed-analytics]: " || SET HONEUR_ANALYTICS_SHARED_FOLDER=%CURRENT_DIRECTORY%\distributed-analytics

SET /p HONEUR_SECURITY_METHOD="Use jdbc users or LDAP or No for authentication? Enter jdbc/ldap/none. [none]: " || SET HONEUR_SECURITY_METHOD=none
:while-security-mode-not-correct
if NOT "%HONEUR_SECURITY_METHOD%" == "none" if NOT "%HONEUR_SECURITY_METHOD%" == "ldap" if NOT "%HONEUR_SECURITY_METHOD%" == "jdbc" (
   echo enter "none", "jdbc", "ldap" or empty for default "none" value
   SET /p HONEUR_SECURITY_METHOD="Use jdbc users or LDAP or No for authentication? Enter jdbc/ldap/none. [none]: " || SET HONEUR_SECURITY_METHOD=none
   goto :while-security-mode-not-correct
)
if "%HONEUR_SECURITY_METHOD%" == "ldap" (
    set /p HONEUR_SECURITY_LDAP_URL="security.ldap.url [ldap://ldap.forumsys.com:389]: " || SET "HONEUR_SECURITY_LDAP_URL=ldap://ldap.forumsys.com:389"
    set /p HONEUR_SECURITY_LDAP_SYSTEM_USERNAME="security.ldap.system.username [cn=read-only-admin,dc=example,dc=com]: " || SET "HONEUR_SECURITY_LDAP_SYSTEM_USERNAME=cn=read-only-admin,dc=example,dc=com"
    set /p HONEUR_SECURITY_LDAP_SYSTEM_PASSWORD="security.ldap.system.password [password]: " || SET HONEUR_SECURITY_LDAP_SYSTEM_PASSWORD=password
    set /p HONEUR_SECURITY_LDAP_BASE_DN="security.ldap.baseDn [dc=example,dc=com]: " || SET "HONEUR_SECURITY_LDAP_BASE_DN=dc=example,dc=com"
    set /p HONEUR_SECURITY_LDAP_DN="security.ldap.dn [uid={0},dc=example,dc=com]: " || SET "HONEUR_SECURITY_LDAP_DN=uid={0},dc=example,dc=com"
)

SET USERID=1000

:installation
echo. 2>honeur-studio.env

echo TAG=%TAG%> honeur-studio.env
echo APPLICATION_LOGS_TO_STDOUT=false>> honeur-studio.env
echo SITE_NAME=honeurstudio>> honeur-studio.env
echo CONTENT_PATH=%HONEUR_HONEUR_STUDIO_FOLDER%>> honeur-studio.env
echo USERID=%USERID%>> honeur-studio.env
echo DOMAIN_NAME=%HONEUR_HOST_MACHINE%>> honeur-studio.env
echo HONEUR_ANALYTICS_SHARED_FOLDER=%HONEUR_ANALYTICS_SHARED_FOLDER%>> honeur-studio.env
echo AUTHENTICATION_METHOD=%HONEUR_SECURITY_METHOD%>> honeur-studio.env
if "%HONEUR_SECURITY_METHOD%" == "jdbc" (
    echo DATASOURCE_DRIVER_CLASS_NAME=org.postgresql.Driver>> honeur-studio.env
    echo DATASOURCE_URL=jdbc:postgresql://postgres:5432/OHDSI?currentSchema=webapi>> honeur-studio.env
    echo WEBAPI_ADMIN_USERNAME=ohdsi_admin_user>> honeur-studio.env
)
if "%HONEUR_SECURITY_METHOD%" == "ldap" (
    echo HONEUR_STUDIO_LDAP_URL=%HONEUR_SECURITY_LDAP_URL%/%HONEUR_SECURITY_LDAP_BASE_DN%>> honeur-studio.env
    echo HONEUR_STUDIO_LDAP_DN=uid={0}>> honeur-studio.env
    echo HONEUR_STUDIO_LDAP_MANAGER_DN=%HONEUR_SECURITY_LDAP_SYSTEM_USERNAME%>> honeur-studio.env
    echo HONEUR_STUDIO_LDAP_MANAGER_PASSWORD=%HONEUR_SECURITY_LDAP_SYSTEM_PASSWORD%>> honeur-studio.env
)

echo. 2>honeur-studio-chronicle.env

echo SITE_NAME=honeurstudio> honeur-studio-chronicle.env
echo USERID=%USERID%>> honeur-studio-chronicle.env
echo USER=honeurstudio>> honeur-studio-chronicle.env

echo Stop and remove all honeur-studio containers if exists
PowerShell -Command "docker stop $(docker ps --filter 'network=honeur-studio-net' -q -a)" >nul 2>&1
PowerShell -Command "docker rm $(docker ps --filter 'network=honeur-studio-net' -q -a)" >nul 2>&1

echo Create honeur-net network if it does not exists
docker network create --driver bridge honeur-net >nul 2>&1
echo Create honeur-studio-frontend-net network if it does not exists
docker network create --driver bridge honeur-studio-frontend-net >nul 2>&1
echo Create honeur-studio-net network if it does not exists
docker network create --driver bridge honeur-studio-net >nul 2>&1

echo Pull honeur/honeur-studio:%TAG% from docker hub. This could take a while if not present on machine
docker pull honeur/honeur-studio:%TAG%

echo Run honeur/honeur-studio:%TAG% container. This could take a while...
docker run ^
--name "honeur-studio-chronicle" ^
--restart on-failure:5 ^
--security-opt no-new-privileges ^
--env-file honeur-studio-chronicle.env ^
--hostname "cronicle" ^
-v "%HONEUR_HONEUR_STUDIO_FOLDER%:/home/honeurstudio/__HONEURStudio__:z" ^
-v "r_libraries:/r-libs" ^
-v "py_environment:/conda" ^
-v "cronicle_data:/opt/cronicle" ^
-v "pwsh_modules:/home/honeurstudio/.local/share/powershell/Modules" ^
-m "500m" ^
--cpus "1" ^
--pids-limit 100 ^
--cpu-shares 1024 ^
--ulimit nofile=1024:1024 ^
-d ^
honeur/honeur-studio:%TAG% cronicle >nul 2>&1

echo Connect honeur-studio-chronicle to honeur-net network
docker network connect honeur-net honeur-studio-chronicle >nul 2>&1
echo Connect honeur-studio-chronicle to honeur-studio-frontend-net network
docker network connect honeur-studio-frontend-net honeur-studio-chronicle >nul 2>&1
echo Connect honeur-studio-chronicle to honeur-studio-net network
docker network connect honeur-studio-net honeur-studio-chronicle >nul 2>&1

echo Run honeur/honeur-studio:%TAG% container. This could take a while...
docker run ^
--name "honeur-studio" ^
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
honeur/honeur-studio:%TAG% shinyproxy >nul 2>&1

echo Connect honeur-studio to honeur-net network
docker network connect honeur-net honeur-studio >nul 2>&1
echo Connect honeur-studio to honeur-studio-frontend-net network
docker network connect honeur-studio-frontend-net honeur-studio >nul 2>&1
echo Connect honeur-studio to honeur-studio-net network
docker network connect honeur-studio-net honeur-studio >nul 2>&1

echo Clean up helper files
DEL /Q honeur-studio.env
DEL /Q honeur-studio-chronicle.env

echo Done
