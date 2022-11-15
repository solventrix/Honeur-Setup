#!/usr/bin/env bash
set -e

DATABASE_NAME=opal

REGISTRY=harbor.honeur.org
SITE=oncocologne
REPOSITORY=ecrf/${SITE}
TAG=0.2.1
NETWORK=honeur-net


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

echo "Take database backup"
if [[ ! -f ./backup_ecrf_db.sh ]]
then
    curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/eCRF_OncoCologne/backup_ecrf_db.sh --output backup_ecrf_db.sh && chmod +x backup_ecrf_db.sh
fi
POSTGRES_PASSWORD=$POSTGRES_PASSWORD ./backup_ecrf_db.sh

echo "Stop running eCRF app"
docker stop honeur_ecrf_app || true
docker rm honeur_ecrf_app || true

echo "Stop running NGINX"
docker stop honeur_ecrf_nginx || true
docker rm honeur_ecrf_nginx || true

echo "Recreate static volume"
docker volume rm static_volume || true
docker volume create static_volume

echo "Install new eCRF app"
docker pull $REGISTRY/$REPOSITORY/app:$TAG
docker run -d --name honeur_ecrf_app --network $NETWORK --volume static_volume:/code/entrytool/assets --env OPAL_SUPER_USER_PASSWORD=$OPAL_SUPER_USER_PASSWORD --env OPAL_DB_USER=postgres --env OPAL_DB_PASSWORD=$POSTGRES_PASSWORD --env OPAL_DB_NAME=$DATABASE_NAME --env OPAL_DB_HOST=honeur_ecrf_postgres --env OPAL_DB_PORT=5432 --env OPAL_FLUSH_DB=false --env OPAL_ENABLE_USER_DB=false --env OPAL_ENABLE_LDAP=false --restart=always $REGISTRY/$REPOSITORY/app:$TAG gunicorn -b 0.0.0.0:8000 entrytool.wsgi
i=1
while [[ $i -lt 20 ]] ; do
   printf "."
   sleep 1
  (( i += 1 ))
done
printf "\n"

echo "Install new NGINX"
docker run -d --name honeur_ecrf_nginx --network $NETWORK -v static_volume:/code/entrytool/assets --restart=always -p 80:80 $REGISTRY/$REPOSITORY/nginx:$TAG

echo "Upgrade successfully completed"