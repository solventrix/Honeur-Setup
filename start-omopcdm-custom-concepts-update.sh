#!/usr/bin/env bash

echo Docker login, Make sure to use an account with access to the honeur docker hub images.
docker login

if [ $? -eq 0 ]
then
    read -p "Press [Enter] to start removing the existing omop-cdm-custom-concepts container"

    echo Stop and remove previous omop-cdm-custom-concepts container. Ignore errors when no such container exists.
    echo stop omop-cdm-custom-concepts
    docker stop omop-cdm-custom-concepts

    echo remove omop-cdm-custom-concepts
    docker rm omop-cdm-custom-concepts

    echo Success
    read -p "Press [Enter] key to continue"

    echo Downloading docker-compose.yml file.
    curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/release/1.9/OMOPCDMCustomConcepts/docker-compose.yml --output docker-compose.yml

    docker-compose pull
    docker-compose up

    echo Removing downloaded files
    rm docker-compose.yml

    echo success

fi
read -p "Press [Enter] key to exit"
echo bye