#!/bin/bash

echo Docker login, Make sure to use an account with access to the honeur docker hub images.
docker login

if [ $? -eq 0 ]
then
    read -p "Press [Enter] to start removing the existing HONEUR containers"

    echo Stop previous HONEUR containers.
    docker stop $(docker ps --filter 'network=honeur-net' -q -a) > /dev/null 2>&1
    docker rm $(docker ps --filter 'network=honeur-net' -q -a) > /dev/null 2>&1

    echo Removing shared volume
    docker volume rm shared > /dev/null 2>&1

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
    read -p 'Enter your HONEUR organization [Janssen]: ' honeur_analytics_organization
    honeur_analytics_organization=${honeur_analytics_organization:-Janssen}
    read -p 'Enter the directory where Zeppelin will save the prepared distributed analytics data [./distributed-analytics]: ' honeur_analytics_shared_folder
    honeur_analytics_shared_folder=${honeur_analytics_shared_folder:-./distributed-analytics}

    sed -i -e "s@CHANGE_HONEUR_BACKEND_HOST@$honeur_host_machine@g" docker-compose.yml
    sed -i -e "s@CHANGE_HONEUR_ZEPPELIN_LOGS@$honeur_zeppelin_logs@g" docker-compose.yml
    sed -i -e "s@CHANGE_HONEUR_ZEPPELIN_NOTEBOOK@$honeur_zeppelin_notebooks@g" docker-compose.yml
    sed -i -e "s@CHANGE_HONEUR_ZEPPELIN_SECURITY@$honeur_ldap_or_jdbc@g" docker-compose.yml
    sed -i -e "s@CHANGE_HONEUR_LDAP_URL@$honeur_security_ldap_url@g" docker-compose.yml
    sed -i -e "s@CHANGE_HONEUR_LDAP_SYSTEM_USERNAME@$honeur_security_ldap_system_username@g" docker-compose.yml
    sed -i -e "s@CHANGE_HONEUR_LDAP_SYSTEM_PASSWORD@$honeur_security_ldap_system_password@g" docker-compose.yml
    sed -i -e "s@CHANGE_HONEUR_LDAP_BASE_DN@$honeur_security_ldap_base_dn@g" docker-compose.yml
    sed -i -e "s@CHANGE_HONEUR_LDAP_DN@$honeur_security_ldap_dn@g" docker-compose.yml
    sed -i -e "s@CHANGE_HONEUR_USERMGMT_ADMIN_USERNAME@$honeur_usermgmt_admin_username@g" docker-compose.yml
    sed -i -e "s@CHANGE_HONEUR_USERMGMT_ADMIN_PASSWORD@$honeur_usermgmt_admin_password@g" docker-compose.yml
    sed -i -e "s@CHANGE_HONEUR_ANALYTICS_ORGANIZATION@$honeur_analytics_organization@g" docker-compose.yml
    sed -i -e "s@CHANGE_HONEUR_DISTRIBUTED_ANALYTICS_SHARED@$honeur_analytics_shared_folder@g" docker-compose.yml

    docker volume create --name pgdata
    docker volume create --name shared
    docker volume create --name r-server-data

    echo export COMPOSE_HTTP_TIMEOUT=3000
    export COMPOSE_HTTP_TIMEOUT=3000

    docker-compose pull
    docker-compose up -d

    echo Removing downloaded files
    rm docker-compose.yml

    echo postgresql is available on $honeur_host_machine:5444
    echo webapi/atlas is available on http://$honeur_host_machine:8080/webapi and http://$honeur_host_machine:8080/atlas respectively
    echo User management is available on http://$honeur_host_machine:8081
    echo Zeppelin is available on http://$honeur_host_machine:8082
    echo Zeppelin Spark Master URL is available on spark://$honeur_host_machine:7077
    echo Zeppelin logs are available in directory $honeur_zeppelin_logs
    echo Zeppelin notebooks are available in directory $honeur_zeppelin_notebooks
fi
read -p "Press [Enter] key to exit"
echo bye