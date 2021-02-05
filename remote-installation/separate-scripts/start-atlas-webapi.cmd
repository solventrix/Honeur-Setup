@echo off

SET VERSION=2.0.1
SET TAG=2.7.1-%VERSION%

set argumentCount=0
for %%x in (%*) do (
    set /A argumentCount+=1
    set "argVec[!argumentCount!]=%%~x"
)

if "%~1" NEQ "" (
    if "%argumentCount%" LSS "2" (
        echo Give all arguments or none to use the interactive script.
        EXIT 1
    )
    SET "HONEUR_HOST_MACHINE=%~1"
    SET "HONEUR_SECURITY_METHOD=%~2"
    SET "HONEUR_SECURITY_LDAP_URL=ldap://localhost:389"
    SET "HONEUR_SECURITY_LDAP_SYSTEM_USERNAME=username"
    SET "HONEUR_SECURITY_LDAP_SYSTEM_PASSWORD=password"
    SET "HONEUR_SECURITY_LDAP_BASE_DN=dc=example,dc=org"
    SET "HONEUR_SECURITY_LDAP_DN=cn={0},dc=example,dc=org"
    if "%~2" EQU "ldap" (
        if "%argumentCount%" LSS "7" (
            echo When LDAP is chosen as security option, please provide ldap properties.
            EXIT 1
        ) else (
            SET "HONEUR_SECURITY_LDAP_URL=%~3"
            SET "HONEUR_SECURITY_LDAP_SYSTEM_USERNAME=%~4"
            SET "HONEUR_SECURITY_LDAP_SYSTEM_PASSWORD=%~5"
            SET "HONEUR_SECURITY_LDAP_BASE_DN=%~6"
            SET "HONEUR_SECURITY_LDAP_DN=%~7"
        )
    )
    goto installation
)

SET /p HONEUR_HOST_MACHINE="Enter the FQDN(Fully Qualified Domain Name eg. www.example.com) or public IP address(eg. 125.24.44.18) of the host machine. Use localhost to for testing [localhost]: " || SET HONEUR_HOST_MACHINE=localhost

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
if "%HONEUR_SECURITY_METHOD%" == "jdbc" (
    SET "HONEUR_SECURITY_LDAP_URL=ldap://localhost:389"
    SET "HONEUR_SECURITY_LDAP_SYSTEM_USERNAME=username"
    SET "HONEUR_SECURITY_LDAP_SYSTEM_PASSWORD=password"
    SET "HONEUR_SECURITY_LDAP_BASE_DN=dc=example,dc=org"
    SET "HONEUR_SECURITY_LDAP_DN=cn={0},dc=example,dc=org"
)

:installation
echo. 2>atlas-webapi.env

echo OHDSI_DATASOURCE_URL=jdbc:postgresql://postgres:5432/OHDSI> atlas-webapi.env
echo WEBAPI_URL=/webapi/>> atlas-webapi.env
echo JAVA_OPTS=-Xms512m -Xmx512m>> atlas-webapi.env
if NOT "%HONEUR_SECURITY_METHOD%" == "none" (
    echo USER_AUTHENTICATION_ENABLED=true>> atlas-webapi.env
    echo LDAP_URL=%HONEUR_SECURITY_LDAP_URL%>> atlas-webapi.env
    echo LDAP_SYSTEM_USERNAME=%HONEUR_SECURITY_LDAP_SYSTEM_USERNAME%>> atlas-webapi.env
    echo LDAP_SYSTEM_PASSWORD=%HONEUR_SECURITY_LDAP_SYSTEM_PASSWORD%>> atlas-webapi.env
    echo LDAP_BASE_DN=%HONEUR_SECURITY_LDAP_BASE_DN%>> atlas-webapi.env
    echo LDAP_DN=%HONEUR_SECURITY_LDAP_DN%>> atlas-webapi.env
) else (
    echo USER_AUTHENTICATION_ENABLED=false>> atlas-webapi.env
)

echo Stop and remove webapi container if exists
docker stop webapi >nul 2>&1
docker rm webapi >nul 2>&1

if NOT "%HONEUR_SECURITY_METHOD%" == "none" (
    SET TAG=%TAG%-secure
) else (
    SET TAG=%TAG%-standard
)

echo Create honeur-net network if it does not exists
docker network create --driver bridge honeur-net >nul 2>&1

echo Pull honeur/webapi-atlas:%TAG% from docker hub. This could take a while if not present on machine
docker pull honeur/webapi-atlas:%TAG%

echo Run honeur/webapi-atlas:%TAG% container. This could take a while...
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
honeur/webapi-atlas:%TAG% >nul 2>&1

echo Connect webapi to honeur-net network
docker network connect honeur-net webapi >nul 2>&1

echo Clean up helper files
DEL /Q atlas-webapi.env

echo Done