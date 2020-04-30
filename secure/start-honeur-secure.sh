#!/bin/bash

echo Docker login, Make sure to use an account with access to the honeur docker hub images.
docker login

if [ $? -eq 0 ]
then
    read -p "Press [Enter] to start removing the existing HONEUR containers"

    echo export COMPOSE_HTTP_TIMEOUT=300
    export COMPOSE_HTTP_TIMEOUT=300

    echo Stop previous HONEUR containers. Ignore errors when no such containers exist yet.
    echo stop webapi
    docker stop webapi
    echo stop zeppelin
    docker stop zeppelin
    echo stop user-mgmt
    docker stop user-mgmt
    echo stop postgres
    docker stop postgres
    
    echo Removing previous HONEUR containers. This can give errors when no such containers exist yet.
    echo remove webapi
    docker rm webapi
    echo remove zeppelin
    docker rm zeppelin
    echo remove user-mgmt
    docker rm user-mgmt
    echo remove postgres
    docker rm postgres

    echo Removing shared volume
    docker volume rm shared
    
    echo Success
    read -p "Press [Enter] key to continue"

    echo Downloading docker-compose.yml file.
    curl -fsSL https://github.com/solventrix/Honeur-Setup/releases/download/v1.5/docker-compose-honeur-secure.yml --output docker-compose.yml
    
    read -p 'Enter the FQDN(Fully Qualified Domain Name eg. www.example.com) or public IP address(eg. 125.24.44.18) of the host machine. Use localhost to for testing [localhost]: ' honeur_host_machine
    honeur_host_machine=${honeur_host_machine:-localhost}
    read -p 'Enter the directory where the zeppelin logs will kept on the host machine [./zeppelin/logs]: ' honeur_zeppelin_logs
    honeur_zeppelin_logs=${honeur_zeppelin_logs:-./zeppelin/logs}
    read -p 'Enter the directory where the zeppelin notebooks will kept on the host machine [./zeppelin/notebook]: ' honeur_zeppelin_notebooks
    honeur_zeppelin_notebooks=${honeur_zeppelin_notebooks:-./zeppelin/notebook}
    read -p "Use WebAPI jdbc users or LDAP for authentication? Enter jdbc or ldap. [jdbc]: " honeur_ldap_or_jdbc
    honeur_ldap_or_jdbc=${honeur_ldap_or_jdbc:-jdbc}
    if [ "$honeur_ldap_or_jdbc" = "ldap" ]
    then
        read -p "security.ldap.url [ldap://ldap.forumsys.com:389]: " honeur_security_ldap_url
        honeur_security_ldap_url=${honeur_security_ldap_url:-ldap://ldap.forumsys.com:389}
        read -p "security.ldap.system.username [cn=read-only-admin,dc=example,dc=com]: " honeur_security_ldap_system_username
        honeur_security_ldap_system_username=${honeur_security_ldap_system_username:-cn=read-only-admin,dc=example,dc=com}
        read -p "security.ldap.system.password [password]: " honeur_security_ldap_system_password
        honeur_security_ldap_system_password=${honeur_security_ldap_system_password:-password}
        read -p "security.ldap.baseDn [dc=example,dc=com]: " honeur_security_ldap_base_dn
        honeur_security_ldap_base_dn=${honeur_security_ldap_base_dn:-dc=example,dc=com}
        read -p "security.ldap.dn [uid={0},dc=example,dc=com]: " honeur_security_ldap_dn
        honeur_security_ldap_dn=${honeur_security_ldap_dn:-uid=\{0\},dc=example,dc=com}
    else
        honeur_security_ldap_url=ldap://localhost:389
        honeur_security_ldap_system_username=username
        honeur_security_ldap_system_password=password
        honeur_security_ldap_base_dn=dc=example,dc=org
        honeur_security_ldap_dn=cn={0},dc=example,dc=org
    fi
    
    read -p "usermgmt admin username [admin]: " honeur_usermgmt_admin_username
    honeur_usermgmt_admin_username=${honeur_usermgmt_admin_username:-admin}
    read -p "usermgmt admin password [admin]: " honeur_usermgmt_admin_password
    honeur_usermgmt_admin_password=${honeur_usermgmt_admin_password:-admin}

    sed -i -e "s@- \"BACKEND_HOST=http://localhost@- \"BACKEND_HOST=http://$honeur_host_machine@g" docker-compose.yml
    sed -i -e "s@- ./zeppelin/logs@- $honeur_zeppelin_logs@g" docker-compose.yml
    sed -i -e "s@- ./zeppelin/notebook@- $honeur_zeppelin_notebooks@g" docker-compose.yml
    sed -i -e "s@- \"ZEPPELIN_SECURITY=jdbc@- \"ZEPPELIN_SECURITY=$honeur_ldap_or_jdbc@g" docker-compose.yml
    sed -i -e "s@- \"LDAP_URL=ldap://ldap.forumsys.com:389@- \"LDAP_URL=$honeur_security_ldap_url@g" docker-compose.yml
    sed -i -e "s@- \"LDAP_SYSTEM_USERNAME=cn=read-only-admin,dc=example,dc=com@- \"LDAP_SYSTEM_USERNAME=$honeur_security_ldap_system_username@g" docker-compose.yml
    sed -i -e "s@- \"LDAP_SYSTEM_PASSWORD=password@- \"LDAP_SYSTEM_PASSWORD=$honeur_security_ldap_system_password@g" docker-compose.yml
    sed -i -e "s@- \"LDAP_BASE_DN=dc=example,dc=com@- \"LDAP_BASE_DN=$honeur_security_ldap_base_dn@g" docker-compose.yml
    sed -i -e "s@- \"LDAP_DN=uid={0},dc=example,dc=com@- \"LDAP_DN=$honeur_security_ldap_dn@g" docker-compose.yml
    sed -i -e "s@- \"HONEUR_USERMGMT_USERNAME=admin@- \"HONEUR_USERMGMT_USERNAME=$honeur_usermgmt_admin_username@g" docker-compose.yml
    sed -i -e "s@- \"HONEUR_USERMGMT_PASSWORD=admin@- \"HONEUR_USERMGMT_PASSWORD=$honeur_usermgmt_admin_password@g" docker-compose.yml
    
    docker volume create --name pgdata
    docker volume create --name shared

    docker-compose pull
    docker-compose up -d
    
    echo Removing downloaded files
    rm docker-compose.yml
    
    echo postgresql is available on $honeur_host_machine:5444
    echo webapi/atlas is available on http://$honeur_host_machine:8080/webapi and http://$honeur_host_machine:8080/atlas respectively
    echo User management is available on http://$honeur_host_machine:8081
    echo Zeppelin is available on http://$honeur_host_machine:8082
fi
read -p "Press [Enter] key to exit"
echo bye