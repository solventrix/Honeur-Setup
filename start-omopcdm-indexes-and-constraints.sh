#!/usr/bin/env bash

echo Docker login, Make sure to use an account with access to the honeur docker hub images.
docker login

if [ $? -eq 0 ]
then
    read -p "Press [Enter] to start removing the existing containers"

    echo Stop previous containers. Ignore errors when no omop-indexes-and-constraints container exist yet.
    echo stop omop-indexes-and-constraints
    docker stop omop-indexes-and-constraints

    echo Removing previous containers. This can give errors when no omop-indexes-and-constraints container exist yet.
    echo remove omop-indexes-and-constraints
    docker rm omop-indexes-and-constraints

    echo Succes
    read -p "Press [Enter] key to continue"

    echo Downloading docker-compose.yml file.
    curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/v2.0.0/OMOPCDMDBIndexesAndContraints/docker-compose.yml --output docker-compose.yml

    docker-compose pull
    docker-compose up

    echo Removing downloaded files
    rm -rf docker-compose.yml

    echo success

fi
read -p "Press [Enter] key to exit"
echo bye