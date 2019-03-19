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
set /p honeur_host_machine="Enter the FQDN(Fully Qualified Domain Name eg. www.example.com) or public IP address(eg. 125.24.44.18) of the host machine. Use localhost to for testing [localhost]: " || SET honeur_host_machine=localhost
set /p honeur_zeppelin_logs="Enter the directory where the zeppelin logs will kept on the host machine [./zeppelin/logs]: " || SET honeur_zeppelin_logs=./zeppelin/logs
set /p honeur_zeppelin_notebooks="Enter the directory where the zeppelin notebooks will kept on the host machine [./zeppelin/notebook]: " || SET honeur_zeppelin_notebooks=./zeppelin/notebook
set /p honeur_security_ldap_url="security.ldap.url [ldap://ldap.forumsys.com:389]: " || SET "honeur_security_ldap_url=ldap://ldap.forumsys.com:389"
set /p honeur_security_ldap_system_username="security.ldap.system.username [cn=read-only-admin,dc=example,dc=com]: " || SET "honeur_security_ldap_system_username=cn=read-only-admin,dc=example,dc=com"
set /p honeur_security_ldap_system_password="security.ldap.system.password [password]: " || SET honeur_security_ldap_system_password=password
set /p honeur_security_ldap_base_dn="security.ldap.baseDn [dc=example,dc=com]: " || SET "honeur_security_ldap_base_dn=dc=example,dc=com"
set /p honeur_security_ldap_dn="security.ldap.dn [uid={0},dc=example,dc=com]: " || SET "honeur_security_ldap_dn=uid={0},dc=example,dc=com"
set /p honeur_usermgmt_admin_username="usermgmt admin username [admin]: " || SET honeur_usermgmt_admin_username=admin
set /p honeur_usermgmt_admin_password="usermgmt admin password [admin]: " || SET honeur_usermgmt_admin_password=admin

sed -i -e 's@BACKEND_HOST: http://localhost@BACKEND_HOST: http://%honeur_host_machine%@g' docker-compose.yml
sed -i -e 's@- ./zeppelin/logs@- %honeur_zeppelin_logs%@g' docker-compose.yml
sed -i -e 's@- ./zeppelin/notebook@- %honeur_zeppelin_notebooks%@g' docker-compose.yml
sed -i -e 's@LDAP_URL: ldap://ldap.forumsys.com:389@LDAP_URL: %honeur_security_ldap_url%@g' docker-compose.yml
sed -i -e 's@LDAP_SYSTEM_USERNAME: cn=read-only-admin,dc=example,dc=com@LDAP_SYSTEM_USERNAME: %honeur_security_ldap_system_username%@g' docker-compose.yml
sed -i -e 's@LDAP_SYSTEM_PASSWORD: password@LDAP_SYSTEM_PASSWORD: %honeur_security_ldap_system_password%@g' docker-compose.yml
sed -i -e 's@LDAP_BASE_DN: dc=example,dc=com@LDAP_BASE_DN: %honeur_security_ldap_base_dn%@g' docker-compose.yml
sed -i -e 's@LDAP_DN: uid={0},dc=example,dc=com@LDAP_DN: %honeur_security_ldap_dn%@g' docker-compose.yml
sed -i -e 's@USERMGMT_ADMIN_USERNAME: admin@USERMGMT_ADMIN_USERNAME: %honeur_usermgmt_admin_username%@g' docker-compose.yml
sed -i -e 's@USERMGMT_ADMIN_PASSWORD: admin@USERMGMT_ADMIN_PASSWORD: %honeur_usermgmt_admin_password%@g' docker-compose.yml

docker volume create --name pgdata
docker volume create --name shared

docker-compose stop
docker-compose rm -f
docker-compose pull
docker-compose up -d

echo postgresql is available on %honeur_host_machine%:5444
echo webapi/atlas is available on http://%honeur_host_machine%:8080/webapi and http://%honeur_host_machine%:8080/atlas respectively
echo User management is available on http://%honeur_host_machine%:8081/usermgmt
echo Zeppelin is available on http://%honeur_host_machine%:8082
goto eof


:eof
echo Press [Enter] key to exit
pause>NUL