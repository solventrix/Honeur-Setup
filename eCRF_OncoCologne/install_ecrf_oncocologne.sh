#!/usr/bin/env bash
set -e

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
docker pull harbor-uat.honeur.org/ecrf/oncocologne/postgres:0.2
docker pull harbor-uat.honeur.org/ecrf/oncocologne/app:0.2
docker pull harbor-uat.honeur.org/ecrf/oncocologne/nginx:0.2

echo "create network feder8-net"
docker network create feder8-net

echo "create volumes postgres_data and static_volume"
docker volume create postgres_data
docker volume create static_volume

echo "create database container"
docker run -d --name honeur_ecrf_postgres --network feder8-net --volume postgres_data:/var/lib/postgresql/data --env POSTGRES_PASSWORD=$POSTGRES_PASSWORD --restart=always harbor-uat.honeur.org/ecrf/oncocologne/postgres:0.2
sleep 5s

echo "create eCRF app container"
if $fresh_install; then
  echo "Fresh install"
  docker run -d --name honeur_ecrf_app --network feder8-net --volume static_volume:/code/entrytool/assets --env OPAL_SUPER_USER_PASSWORD=$OPAL_SUPER_USER_PASSWORD --env OPAL_DB_USER=postgres --env OPAL_DB_PASSWORD=$POSTGRES_PASSWORD --env OPAL_DB_NAME=postgres --env OPAL_DB_HOST=honeur_ecrf_postgres --env OPAL_DB_PORT=5432 --env OPAL_FLUSH_DB=true --env OPAL_ENABLE_USER_DB=false --env OPAL_ENABLE_LDAP=false harbor-uat.honeur.org/ecrf/oncocologne/app:0.2 gunicorn -b 0.0.0.0:8000 entrytool.wsgi
  sleep 15s
  docker stop honeur_ecrf_app
  docker rm honeur_ecrf_app
fi

docker run -d --name honeur_ecrf_app --network feder8-net --volume static_volume:/code/entrytool/assets --env OPAL_SUPER_USER_PASSWORD=$OPAL_SUPER_USER_PASSWORD --env OPAL_DB_USER=postgres --env OPAL_DB_PASSWORD=$POSTGRES_PASSWORD --env OPAL_DB_NAME=postgres --env OPAL_DB_HOST=honeur_ecrf_postgres --env OPAL_DB_PORT=5432 --env OPAL_FLUSH_DB=false --env OPAL_ENABLE_USER_DB=false --env OPAL_ENABLE_LDAP=false --restart=always harbor-uat.honeur.org/ecrf/oncocologne/app:0.2 gunicorn -b 0.0.0.0:8000 entrytool.wsgi
sleep 15s

echo "create nginx container"
docker run -d --name honeur_ecrf_nginx --network feder8-net -v static_volume:/code/entrytool/assets --restart=always -p 80:80 harbor-uat.honeur.org/ecrf/oncocologne/nginx:0.2
