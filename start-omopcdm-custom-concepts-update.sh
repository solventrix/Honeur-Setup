#!/bin/sh

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

    echo Creating folder setup-conf
    mkdir setup-conf
    echo Downloading docker-compose.yml file.
    curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/OMOPCDMCustomConcepts/docker-compose.yml --output docker-compose.yml
    echo Downloading setup.yml file inside setup-conf folder
    curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/OMOPCDMCustomConcepts/setup-conf/setup.yml --output setup-conf/setup.yml

    docker-compose pull
    docker-compose up -d

    sleep 5

    echo Removing downloaded files
    rm docker-compose.yml
    rm -R setup-conf

    echo success

fi
read -p "Press [Enter] key to exit"
echo bye