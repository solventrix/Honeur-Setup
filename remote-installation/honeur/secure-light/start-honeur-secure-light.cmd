@echo off

echo Docker login, Make sure to use an account with access to the honeur docker hub images.
docker login

IF %ERRORLEVEL% EQU 0 (
    goto honeur_setup
) else (
    echo Failed to Login
    goto eof
)

:honeur_setup
echo Press [Enter] to start removing the existing HONEUR containers
pause>NUL

echo Stop and Remove previous HONEUR containers.
PowerShell -Command "docker stop $(docker ps --filter 'network=honeur-net' -q -a)" >nul 2>&1
PowerShell -Command "docker rm $(docker ps --filter 'network=honeur-net' -q -a)" >nul 2>&1

echo Removing shared volume
docker volume rm shared >nul 2>&1

echo Success
echo Press [Enter] key to continue
pause>NUL

echo Downloading docker-compose.yml file.
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/remote-installation/honeur/secure-light/docker-compose-honeur-secure-light.yml --output docker-compose.yml

set /p honeur_host_machine="Enter the FQDN(Fully Qualified Domain Name eg. www.example.com) or public IP address(eg. 125.24.44.18) of the host machine. Use localhost to for testing [localhost]: " || SET honeur_host_machine=localhost
set /p honeur_zeppelin_logs="Enter the directory where the zeppelin logs will kept on the host machine [./zeppelin/logs]: " || SET honeur_zeppelin_logs=./zeppelin/logs
set /p honeur_zeppelin_notebooks="Enter the directory where the zeppelin notebooks will kept on the host machine [./zeppelin/notebook]: " || SET honeur_zeppelin_notebooks=./zeppelin/notebook

set /p honeur_ldap_or_jdbc="Use WebAPI jdbc users or LDAP for authentication? Enter jdbc or ldap. [jdbc]: " || SET honeur_ldap_or_jdbc=jdbc

IF "%honeur_ldap_or_jdbc%" == "ldap" (
    set /p honeur_security_ldap_url="security.ldap.url [ldap://ldap.forumsys.com:389]: " || SET "honeur_security_ldap_url=ldap://ldap.forumsys.com:389"
    set /p honeur_security_ldap_system_username="security.ldap.system.username [cn=read-only-admin,dc=example,dc=com]: " || SET "honeur_security_ldap_system_username=cn=read-only-admin,dc=example,dc=com"
    set /p honeur_security_ldap_system_password="security.ldap.system.password [password]: " || SET honeur_security_ldap_system_password=password
    set /p honeur_security_ldap_base_dn="security.ldap.baseDn [dc=example,dc=com]: " || SET "honeur_security_ldap_base_dn=dc=example,dc=com"
    set /p honeur_security_ldap_dn="security.ldap.dn [uid={0},dc=example,dc=com]: " || SET "honeur_security_ldap_dn=uid={0},dc=example,dc=com"
) ELSE (
    set "honeur_security_ldap_url=ldap://localhost:389"
    set "honeur_security_ldap_system_username=username"
    set "honeur_security_ldap_system_password=password"
    set "honeur_security_ldap_base_dn=dc=example,dc=org"
    set "honeur_security_ldap_dn=cn={0},dc=example,dc=org"
)

set /p honeur_usermgmt_admin_username="usermgmt admin username [admin]: " || SET honeur_usermgmt_admin_username=admin
set /p honeur_usermgmt_admin_password="usermgmt admin password [admin]: " || SET honeur_usermgmt_admin_password=admin

PowerShell -Command "((get-content docker-compose.yml -raw) -replace 'CHANGE_HONEUR_BACKEND_HOST','%honeur_host_machine%') | Set-Content docker-compose.yml"
PowerShell -Command "((get-content docker-compose.yml -raw) -replace 'CHANGE_HONEUR_ZEPPELIN_LOGS','%honeur_zeppelin_logs%') | Set-Content docker-compose.yml"
PowerShell -Command "((get-content docker-compose.yml -raw) -replace 'CHANGE_HONEUR_ZEPPELIN_NOTEBOOKS','%honeur_zeppelin_notebooks%') | Set-Content docker-compose.yml"
PowerShell -Command "((get-content docker-compose.yml -raw) -replace 'CHANGE_HONEUR_ZEPPELIN_SECURITY','%honeur_ldap_or_jdbc%') | Set-Content docker-compose.yml"
PowerShell -Command "((get-content docker-compose.yml -raw) -replace 'CHANGE_HONEUR_LDAP_URL','%honeur_security_ldap_url%') | Set-Content docker-compose.yml"
PowerShell -Command "((get-content docker-compose.yml -raw) -replace 'CHANGE_HONEUR_LDAP_SYSTEM_USERNAME','%honeur_security_ldap_system_username%') | Set-Content docker-compose.yml"
PowerShell -Command "((get-content docker-compose.yml -raw) -replace 'CHANGE_HONEUR_LDAP_SYSTEM_PASSWORD','%honeur_security_ldap_system_password%') | Set-Content docker-compose.yml"
PowerShell -Command "((get-content docker-compose.yml -raw) -replace 'CHANGE_HONEUR_LDAP_BASE_DN','%honeur_security_ldap_base_dn%') | Set-Content docker-compose.yml"
PowerShell -Command "((get-content docker-compose.yml -raw) -replace 'CHANGE_HONEUR_LDAP_DN','%honeur_security_ldap_dn%') | Set-Content docker-compose.yml"
PowerShell -Command "((get-content docker-compose.yml -raw) -replace 'CHANGE_HONEUR_USERMGMT_ADMIN_USERNAME','%honeur_usermgmt_admin_username%') | Set-Content docker-compose.yml"
PowerShell -Command "((get-content docker-compose.yml -raw) -replace 'CHANGE_HONEUR_USERMGMT_ADMIN_PASSWORD','%honeur_usermgmt_admin_password%') | Set-Content docker-compose.yml"

docker volume create --name pgdata
docker volume create --name shared

echo set COMPOSE_HTTP_TIMEOUT=3000
set COMPOSE_HTTP_TIMEOUT=3000

docker-compose pull
docker-compose up -d

echo Removing downloaded files
del docker-compose.yml

echo postgresql is available on %honeur_host_machine%:5444
echo webapi/atlas is available on http://%honeur_host_machine%:8080/webapi and http://%honeur_host_machine%:8080/atlas respectively
echo User management is available on http://%honeur_host_machine%:8081
echo Zeppelin is available on http://%honeur_host_machine%:8082
echo Zeppelin Spark Master URL is available on spark://%honeur_host_machine%:7077
echo Zeppelin logs are available in directory %honeur_zeppelin_logs%
echo Zeppelin notebooks are available in directory %honeur_zeppelin_notebooks%
goto eof


:eof
echo Press [Enter] key to exit
pause>NUL