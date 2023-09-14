#!/usr/bin/env bash
set -e

DATABASE_NAME=opal
BACKUP_FOLDER=${PWD}/backup
NETWORK=feder8-net

if [[ "$POSTGRES_PASSWORD" == "" ]]
then
POSTGRES_PASSWORD=
read -p "Please enter the password for Postgres: " POSTGRES_PASSWORD
while [[ "$POSTGRES_PASSWORD" == "" ]]; do
    echo "The password cannot be empty"
    read -p "Please enter the password for Postgres: " POSTGRES_PASSWORD
done
fi

create_db_dump () {
  mkdir -p ${BACKUP_FOLDER}
  DB_NAME=$1
  PGPASSWORD=$2
  echo "Create dump of database $DB_NAME from postgres"
  docker run \
  --network=$NETWORK \
  --rm \
  -e DB_NAME=$DB_NAME \
  -e PGPASSWORD=$PGPASSWORD \
  -v ${BACKUP_FOLDER}:/opt/database \
  postgres:13.0-alpine sh -c 'set -e; cd /opt/database; export CURRENT_TIME=$(date "+%Y-%m-%d_%H-%M-%S"); PGPASSWORD=${PGPASSWORD} pg_dump --clean --create -h ecrf-postgres -U postgres -Fc ${DB_NAME} > /opt/database/${DB_NAME}_${CURRENT_TIME}.dump'
}

create_db_dump $DATABASE_NAME $POSTGRES_PASSWORD

