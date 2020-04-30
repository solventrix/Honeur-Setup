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

echo set COMPOSE_HTTP_TIMEOUT=300
set COMPOSE_HTTP_TIMEOUT=300

echo Stop and Remove previous HONEUR containers. Ignore errors when no such containers exist yet.
echo Stop and Remove webapi
docker stop webapi && docker rm webapi
echo Stop and Remove zeppelin
docker stop zeppelin && docker rm zeppelin
echo Stop and Remove user-mgmt
docker stop user-mgmt && docker rm user-mgmt
echo Stop and Remove postgres
docker stop postgres && docker rm postgres

echo Removing shared volume
docker volume rm shared

echo Success
echo Press [Enter] key to continue
pause>NUL

echo Downloading docker-compose.yml file.
curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/secure/docker-compose.yml --output docker-compose.yml
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

PowerShell -Command "((get-content docker-compose.yml -raw) -replace 'BACKEND_HOST=http://localhost','BACKEND_HOST=http://%honeur_host_machine%') | Set-Content docker-compose.yml"
PowerShell -Command "((get-content docker-compose.yml -raw) -replace '- ./zeppelin/logs','- %honeur_zeppelin_logs%') | Set-Content docker-compose.yml"
PowerShell -Command "((get-content docker-compose.yml -raw) -replace '- ./zeppelin/notebook','- %honeur_zeppelin_notebooks%') | Set-Content docker-compose.yml"
PowerShell -Command "((get-content docker-compose.yml -raw) -replace '- \"ZEPPELIN_SECURITY=jdbc','- \"ZEPPELIN_SECURITY=%honeur_ldap_or_jdbc%') | Set-Content docker-compose.yml"
PowerShell -Command "((get-content docker-compose.yml -raw) -replace '- \"LDAP_URL=ldap://ldap.forumsys.com:389','- \"LDAP_URL=%honeur_security_ldap_url%') | Set-Content docker-compose.yml"
PowerShell -Command "((get-content docker-compose.yml -raw) -replace '- \"LDAP_SYSTEM_USERNAME=cn=read-only-admin,dc=example,dc=com','- \"LDAP_SYSTEM_USERNAME=%honeur_security_ldap_system_username%') | Set-Content docker-compose.yml"
PowerShell -Command "((get-content docker-compose.yml -raw) -replace '- \"LDAP_SYSTEM_PASSWORD=password','- \"LDAP_SYSTEM_PASSWORD=%honeur_security_ldap_system_password%') | Set-Content docker-compose.yml"
PowerShell -Command "((get-content docker-compose.yml -raw) -replace '- \"LDAP_BASE_DN=dc=example,dc=com','- \"LDAP_BASE_DN=%honeur_security_ldap_base_dn%') | Set-Content docker-compose.yml"
PowerShell -Command "((get-content docker-compose.yml -raw) -replace '- \"LDAP_DN=uid=\{0\},dc=example,dc=com','- \"LDAP_DN=%honeur_security_ldap_dn%') | Set-Content docker-compose.yml"
PowerShell -Command "((get-content docker-compose.yml -raw) -replace '- \"HONEUR_USERMGMT_USERNAME=admin','- \"HONEUR_USERMGMT_USERNAME=%honeur_usermgmt_admin_username%') | Set-Content docker-compose.yml"
PowerShell -Command "((get-content docker-compose.yml -raw) -replace '- \"HONEUR_USERMGMT_PASSWORD=admin','- \"HONEUR_USERMGMT_PASSWORD=%honeur_usermgmt_admin_password%') | Set-Content docker-compose.yml"

docker volume create --name pgdata
docker volume create --name shared

docker-compose pull
docker-compose up -d

echo Removing downloaded files
del docker-compose.yml

echo postgresql is available on %honeur_host_machine%:5444
echo webapi/atlas is available on http://%honeur_host_machine%:8080/webapi and http://%honeur_host_machine%:8080/atlas respectively
echo User management is available on http://%honeur_host_machine%:8081
echo Zeppelin is available on http://%honeur_host_machine%:8082
goto eof

:eof
echo Press [Enter] key to exit
pause>NUL