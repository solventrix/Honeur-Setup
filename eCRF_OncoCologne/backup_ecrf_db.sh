#!/usr/bin/env bash
set -e

POSTGRES_PASSWORD=
read -p "Please enter the password for Postgres: " POSTGRES_PASSWORD
while [[ "$POSTGRES_PASSWORD" == "" ]]; do
    echo "The password cannot be empty"
    read -p "Please enter the password for Postgres: " POSTGRES_PASSWORD
done

DATABASE_NAME=postgres
BACKUP_FOLDER=${PWD}/backup

create_db_dump () {
  mkdir -p ${BACKUP_FOLDER}
  DB_NAME=$1
  PGPASSWORD=$2
  echo "Create dump of database $DB_NAME from postgres"
  docker run \
  --network="honeur-net" \
  --rm \
  -e DB_NAME=$DB_NAME \
  -e PGPASSWORD=$PGPASSWORD \
  -v ${BACKUP_FOLDER}:/opt/database \
  postgres:13.0-alpine sh -c 'set -e; cd /opt/database; PGPASSWORD=${PGPASSWORD} pg_dump -h honeur_ecrf_postgres -U postgres -f ${DB_NAME}.sql -d ${DB_NAME}'
}

tar_dump() {
  echo "Create tar.gz file of database dump"

  cd ${BACKUP_FOLDER}

  DB_NAME=$1
  CURRENT_TIME=$(date "+%Y-%m-%d_%H:%M:%S")

  export LANG=en_US.UTF-8
  export LC_ALL=$LANG
  tar -czf ${DB_NAME}_${CURRENT_TIME}.tar.gz $DB_NAME.sql

  rm $DB_NAME.sql
}

create_db_dump $DATABASE_NAME $POSTGRES_PASSWORD
tar_dump $DATABASE_NAME
