#!/bin/sh

echo Docker login, Make sure to use an account with access to the honeur docker hub images.
docker login

if [ $? -eq 0 ]
then
    read -p "Press [Enter] to start removing the existing containers"

    echo Stop previous containers. Ignore errors when no containers exist yet.
    echo stop postgres-qa
    docker stop postgres-qa
    echo stop webapi-source-qa-enable
    docker stop webapi-source-qa-enable

    echo Removing previous containers. This can give errors when no containers exist yet.
    echo remove postgres-qa
    docker rm postgres-qa
    echo remove webapi-source-qa-enable
    docker rm webapi-source-qa-enable

    echo Succes
    read -p "Press [Enter] key to continue"

    mkdir setup-conf
    echo Downloading docker-compose.yml file.
    curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/WebAPIDBQASourceCreation/docker-compose.yml --output docker-compose.yml
    echo Downloading setup.yml file inside setup-conf folder
    curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/WebAPIDBQASourceCreation/setup-conf/setup.yml --output setup-conf/setup.yml

    docker volume create --name pgdata-qa
    docker volume create --name shared-qa

    docker-compose pull
    docker-compose up

    sleep 5

    echo Removing downloaded files
    rm docker-compose.yml
    rm -R setup-conf

    echo postgresql is available on localhost:5445
fi
read -p "Press [Enter] key to exit"
echo bye