#!/usr/bin/env bash
set -e

REGISTRY=harbor.honeur.org
SITE=zaragosa
REPOSITORY=ecrf/${SITE}
VERSION=0.2.4
NETWORK=feder8-net
DATABASE_NAME=postgres

POSTGRES_PASSWORD=
read -p "Please enter the password for Postgres: " POSTGRES_PASSWORD
while [[ "$POSTGRES_PASSWORD" == "" ]]; do
    echo "The password cannot be empty"
    read -p "Please enter the password for Postgres: " POSTGRES_PASSWORD
done

OPAL_SUPER_USER_PASSWORD=
read -p "Please enter the password for the 'super' user of the eCRF tool: " OPAL_SUPER_USER_PASSWORD
while [[ "$OPAL_SUPER_USER_PASSWORD" == "" ]]; do
    echo "The password cannot be empty"
    read -p "Please enter the password for the 'super' user of the eCRF tool: " OPAL_SUPER_USER_PASSWORD
done

echo "pull docker image"
docker pull $REGISTRY/$REPOSITORY/app:$VERSION

echo "stop and remove existing eCRF app container"
docker stop ecrf-app
docker rm ecrf-app

echo "create new eCRF app container"
docker run -d --name ecrf-app --network $NETWORK --volume static_volume:/code/entrytool/assets --env OPAL_SUPER_USER_PASSWORD=$OPAL_SUPER_USER_PASSWORD --env OPAL_DB_USER=postgres --env OPAL_DB_PASSWORD=$POSTGRES_PASSWORD --env OPAL_DB_NAME=$DATABASE_NAME --env OPAL_DB_HOST=ecrf-postgres --env OPAL_DB_PORT=5432 --env OPAL_FLUSH_DB=false --env OPAL_ENABLE_USER_DB=false --env OPAL_ENABLE_LDAP=false --restart=always $REGISTRY/$REPOSITORY/app:$VERSION gunicorn -b 0.0.0.0:8000 --timeout 300 entrytool.wsgi
i=1
while [[ $i -lt 20 ]] ; do
   printf "."
   sleep 1
  (( i += 1 ))
done
printf "\n"
