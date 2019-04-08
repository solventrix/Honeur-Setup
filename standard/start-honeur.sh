#!/bin/bash

echo Docker login, Make sure to use an account with access to the honeur docker hub images.
docker login

if [ $? -eq 0 ]
then
    read -p "Press [Enter] to start removing the existing containers"

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
    
    echo Succes
    read -p "Press [Enter] key to continue"

    echo Downloading docker-compose.yml file.
    curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/standard/docker-compose.yml --output docker-compose.yml

    read -p 'Enter the FQDN(Fully Qualified Domain Name eg. www.example.com) or public IP address(eg. 125.24.44.18) of the host machine. Use localhost to for testing [localhost]: ' honeur_host_machine
    honeur_host_machine=${honeur_host_machine:-localhost}
    read -p 'Enter the directory where the zeppelin logs will kept on the host machine [./zeppelin/logs]: ' honeur_zeppelin_logs
    honeur_zeppelin_logs=${honeur_zeppelin_logs:-./zeppelin/logs}
    read -p 'Enter the directory where the zeppelin notebooks will kept on the host machine [./zeppelin/notebook]: ' honeur_zeppelin_notebooks
    honeur_zeppelin_notebooks=${honeur_zeppelin_notebooks:-./zeppelin/notebook}

    sed -i -e "s@- \"BACKEND_HOST=http://localhost@- \"BACKEND_HOST=http://$honeur_host_machine@g" docker-compose.yml
    sed -i -e "s@- ./zeppelin/logs@- $honeur_zeppelin_logs@g" docker-compose.yml
    sed -i -e "s@- ./zeppelin/notebook@- $honeur_zeppelin_notebooks@g" docker-compose.yml

    docker volume create --name pgdata
    docker volume create --name shared

    docker-compose pull
    docker-compose up -d
    
    echo Removing downloaded files
    rm docker-compose.yml
    
    echo postgresql is available on $honeur_host_machine:5444
    echo webapi/atlas is available on http://$honeur_host_machine:8080/webapi and http://$honeur_host_machine:8080/atlas respectively
    echo Zeppelin is available on http://$honeur_host_machine:8082
    echo Zeppelin logs are available in directory $honeur_zeppelin_logs
    echo Zeppelin notebooks are available in directory $honeur_zeppelin_notebooks

fi
read -p "Press [Enter] key to exit"
echo bye