@echo off

SET VERSION=2.0.0
SET TAG=0.8.2-%VERSION%
SET CURRENT_DIRECTORY=%CD%

SET /p HONEUR_ZEPPELIN_LOGS="Enter the directory where the zeppelin logs will kept on the host machine [%CURRENT_DIRECTORY%\zeppelin\logs]: " || SET HONEUR_ZEPPELIN_LOGS=%CURRENT_DIRECTORY%\zeppelin\logs
SET /p HONEUR_ZEPPELIN_NOTEBOOKS="Enter the directory where the zeppelin notebooks will kept on the host machine [%CURRENT_DIRECTORY%\zeppelin\notebook]: " || SET HONEUR_ZEPPELIN_NOTEBOOKS=%CURRENT_DIRECTORY%\zeppelin\notebook
SET /p HONEUR_ANALYTICS_SHARED_FOLDER="Enter the directory where Zeppelin will save the prepared distributed analytics data [%CURRENT_DIRECTORY%\distributed-analytics]: " || SET HONEUR_ANALYTICS_SHARED_FOLDER=%CURRENT_DIRECTORY%\distributed-analytics

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

echo. 2>zeppelin.env

echo ZEPPELIN_NOTEBOOK_DIR=/notebook> zeppelin.env
echo ZEPPELIN_LOG_DIR=/logs>> zeppelin.env
if "%HONEUR_SECURITY_METHOD%" == "jdbc" (
    echo ZEPPELIN_SECURITY=%HONEUR_SECURITY_METHOD%>> zeppelin.env
    echo LDAP_URL=ldap://localhost:389>> zeppelin.env
    echo LDAP_BASE_DN=dc=example,dc=org>> zeppelin.env
    echo LDAP_DN=cn={0},dc=example,dc=org>> zeppelin.env
)
if "%HONEUR_SECURITY_METHOD%" == "ldap" (
    echo ZEPPELIN_SECURITY=%HONEUR_SECURITY_METHOD%>> zeppelin.env
    echo LDAP_URL=%HONEUR_SECURITY_LDAP_URL%>> zeppelin.env
    echo LDAP_BASE_DN=%HONEUR_SECURITY_LDAP_BASE_DN%>> zeppelin.env
    echo LDAP_DN=%HONEUR_SECURITY_LDAP_DN%>> zeppelin.env
)

echo Stop and remove zeppelin container if exists
docker stop zeppelin >nul 2>&1
docker rm zeppelin >nul 2>&1

echo Create honeur-net network if it does not exists
docker network create --driver bridge honeur-net >nul 2>&1

echo Pull honeur/zeppelin:%TAG% from docker hub. This could take a while if not present on machine
docker pull honeur/zeppelin:%TAG% >nul 2>&1

echo Run honeur/zeppelin:%TAG% container. This could take a while...
docker run ^
--name "zeppelin" ^
--restart always ^
--security-opt no-new-privileges ^
--env-file zeppelin.env ^
-v "shared:/var/lib/shared:ro" ^
-v "%HONEUR_ANALYTICS_SHARED_FOLDER%:/usr/local/src/datafiles" ^
-v "%HONEUR_ZEPPELIN_LOGS%:/logs" ^
-v "%HONEUR_ZEPPELIN_NOTEBOOKS%:/notebook" ^
-d ^
honeur/zeppelin:%TAG% >nul 2>&1

echo Connect zeppelin to honeur-net network
docker network connect honeur-net zeppelin >nul 2>&1

echo Clean up helper files
DEL /Q zeppelin.env

echo Done