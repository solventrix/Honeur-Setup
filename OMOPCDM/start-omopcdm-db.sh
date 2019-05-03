#!/bin/bash

echo Docker login, Make sure to use an account with access to the HONEUR docker hub images.
docker login

if [ $? -eq 0 ]
then
    read -p "Press [Enter] to stop and remove the existing HONEUR OMOP CDM DB container (if existing)"

    export COMPOSE_HTTP_TIMEOUT=300

    echo Stop previous HONEUR OMOP CDM DB container. Ignore errors when no such container exists.
    docker stop postgres

    echo Remove previous HONEUR OMOP CDM DB container. Ignore errors when no such container exists.
    docker rm postgres

    echo Removing shared volume
    docker volume rm shared

    echo Success
    read -p "Press [Enter] key to continue"

    echo Downloading docker-compose.yml file.
    curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/OMOPCDM/docker-compose.yml --output docker-compose.yml

    echo Creating volumes
    docker volume create --name pgdata
    docker volume create --name shared

    echo Downloading database
    docker-compose pull

    echo Starting database
    docker-compose up -d

    echo Cleaning up
    rm docker-compose.yml

    echo postgresql is available on localhost:5444

fi
read -p "Press [Enter] key to exit"
echo bye