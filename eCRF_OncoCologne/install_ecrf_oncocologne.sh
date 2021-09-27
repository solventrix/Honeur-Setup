#!/usr/bin/env bash
set -e

export POSTGRES_PASSWORD=gyZcrz9Zzp@8waX8
export OPAL_SUPER_USER_PASSWORD=9gM6W8#qjUX8E7B8

echo "pull docker images"
docker pull harbor.honeur.org/ecrf/postgres:0.2
docker pull harbor.honeur.org/ecrf/app:0.2
docker pull harbor.honeur.org/ecrf/nginx:0.2

echo "create network honeur-net"
docker network create honeur-net

echo "create volumes postgres_data and static_volume"
docker volume create postgres_data
docker volume create static_volume

echo "create database container"
docker run -d --name honeur_ecrf_postgres --network honeur-net --volume postgres_data:/var/lib/postgresql/data --env POSTGRES_PASSWORD=$POSTGRES_PASSWORD --restart=always harbor.honeur.org/ecrf/postgres:0.2
sleep 5s

echo "create eCRF app container"
docker run -d --name honeur_ecrf_app --network honeur-net --volume static_volume:/code/entrytool/assets --env OPAL_SUPER_USER_PASSWORD=$OPAL_SUPER_USER_PASSWORD --env OPAL_DB_USER=postgres --env OPAL_DB_PASSWORD=$POSTGRES_PASSWORD --env OPAL_DB_NAME=postgres --env OPAL_DB_HOST=honeur_ecrf_postgres --env OPAL_DB_PORT=5432 --env OPAL_FLUSH_DB=true --env OPAL_ENABLE_USER_DB=false --env OPAL_ENABLE_LDAP=false harbor.honeur.org/ecrf/app:0.2 gunicorn -b 0.0.0.0:8000 entrytool.wsgi
sleep 15s
docker stop honeur_ecrf_app
docker rm honeur_ecrf_app
docker run -d --name honeur_ecrf_app --network honeur-net --volume static_volume:/code/entrytool/assets --env OPAL_SUPER_USER_PASSWORD=$OPAL_SUPER_USER_PASSWORD --env OPAL_DB_USER=postgres --env OPAL_DB_PASSWORD=$POSTGRES_PASSWORD --env OPAL_DB_NAME=postgres --env OPAL_DB_HOST=honeur_ecrf_postgres --env OPAL_DB_PORT=5432 --env OPAL_FLUSH_DB=false --env OPAL_ENABLE_USER_DB=false --env OPAL_ENABLE_LDAP=false --restart=always harbor.honeur.org/ecrf/app:0.2 gunicorn -b 0.0.0.0:8000 entrytool.wsgi
sleep 15s

echo "create nginx container"
docker run -d --name honeur_ecrf_nginx --network honeur-net -v static_volume:/code/entrytool/assets --restart=always -p 80:80 harbor.honeur.org/ecrf/nginx:0.2

unset POSTGRES_PASSWORD
unset OPAL_SUPER_USER_PASSWORD



