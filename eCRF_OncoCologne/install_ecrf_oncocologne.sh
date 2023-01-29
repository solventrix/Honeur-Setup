#!/usr/bin/env bash
set -e

REGISTRY=harbor.honeur.org
SITE=oncocologne
REPOSITORY=ecrf/${SITE}
VERSION=0.2.1
NETWORK=honeur-net
DATABASE_NAME=opal

POSTGRES_PASSWORD=
read -p "Please enter a strong password for Postgres: " POSTGRES_PASSWORD
while [[ "$POSTGRES_PASSWORD" == "" ]]; do
    echo "The password cannot be empty"
    read -p "Please enter a strong password for Postgres: " POSTGRES_PASSWORD
done

OPAL_SUPER_USER_PASSWORD=
read -p "Please enter a strong password for the 'super' user of the eCRF tool: " OPAL_SUPER_USER_PASSWORD
while [[ "$OPAL_SUPER_USER_PASSWORD" == "" ]]; do
    echo "The password cannot be empty"
    read -p "Please enter a strong password for the 'super' user of the eCRF tool: " OPAL_SUPER_USER_PASSWORD
done

fresh_install=false
if [[ $(docker volume inspect postgres_data | grep -q 'Error') != 0 ]]; then
  fresh_install=true
fi

echo "pull docker images"
docker pull $REGISTRY/$REPOSITORY/postgres:$VERSION
docker pull $REGISTRY/$REPOSITORY/app:$VERSION
docker pull $REGISTRY/$REPOSITORY/nginx:$VERSION

echo "create network $NETWORK"
docker network create $NETWORK || true

echo "create volumes postgres_data and static_volume"
docker volume create postgres_data
docker volume create static_volume

echo "create database container"
docker run -d --name honeur_ecrf_postgres --network $NETWORK -p 5432:5432 --volume postgres_data:/var/lib/postgresql/data --env POSTGRES_PASSWORD=$POSTGRES_PASSWORD --restart=always $REGISTRY/$REPOSITORY/postgres:$VERSION
echo "waiting on database container..."
i=1
while [[ $i -lt 30 ]] ; do
   printf "."
   sleep 1
  (( i += 1 ))
done
printf "\n"


echo "create eCRF app container"
if $fresh_install; then
  echo "Fresh install"
  echo "Initializing.  This will take some time..."
  docker run -d --name honeur_ecrf_app --network $NETWORK --volume static_volume:/code/entrytool/assets --env OPAL_SUPER_USER_PASSWORD=$OPAL_SUPER_USER_PASSWORD --env OPAL_DB_USER=postgres --env OPAL_DB_PASSWORD=$POSTGRES_PASSWORD --env OPAL_DB_NAME=$DATABASE_NAME --env OPAL_DB_HOST=honeur_ecrf_postgres --env OPAL_DB_PORT=5432 --env OPAL_FLUSH_DB=true --env OPAL_ENABLE_USER_DB=false --env OPAL_ENABLE_LDAP=false $REGISTRY/$REPOSITORY/app:$VERSION gunicorn -b 0.0.0.0:8000 entrytool.wsgi
  i=1
  while [[ $i -lt 120 ]] ; do
     printf "."
     sleep 1
    (( i += 1 ))
  done
  printf "\n"
  docker stop honeur_ecrf_app
  printf "\n"
  docker rm honeur_ecrf_app
fi
printf "\n"

echo "start eCRF app container"
docker run -d --name honeur_ecrf_app --network $NETWORK --volume static_volume:/code/entrytool/assets --env OPAL_SUPER_USER_PASSWORD=$OPAL_SUPER_USER_PASSWORD --env OPAL_DB_USER=postgres --env OPAL_DB_PASSWORD=$POSTGRES_PASSWORD --env OPAL_DB_NAME=$DATABASE_NAME --env OPAL_DB_HOST=honeur_ecrf_postgres --env OPAL_DB_PORT=5432 --env OPAL_FLUSH_DB=false --env OPAL_ENABLE_USER_DB=false --env OPAL_ENABLE_LDAP=false --restart=always $REGISTRY/$REPOSITORY/app:$VERSION gunicorn -b 0.0.0.0:8000 entrytool.wsgi
i=1
while [[ $i -lt 20 ]] ; do
   printf "."
   sleep 1
  (( i += 1 ))
done
printf "\n"

echo "create NGINX container"
docker run -d --name honeur_ecrf_nginx --network $NETWORK -v static_volume:/code/entrytool/assets --restart=always -p 80:80 $REGISTRY/$REPOSITORY/nginx:$VERSION
