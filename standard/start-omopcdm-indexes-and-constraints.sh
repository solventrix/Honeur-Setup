#!/bin/sh

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

    echo Creating folder setup-conf
    mkdir setup-conf
    echo Downloading docker-compose.yml file.
    curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/standard/OMOPCDMDBIndexesAndContraints/docker-compose.yml --output docker-compose.yml
    echo Downloading setup.yml file inside setup-conf folder
    curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/standard/OMOPCDMDBIndexesAndContraints/setup-conf/setup.yml --output setup-conf/setup.yml

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