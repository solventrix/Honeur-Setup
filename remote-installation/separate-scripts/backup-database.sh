#!/usr/bin/env bash
set -e

BACKUP_FOLDER=${PWD}/backup

create_db_dump () {
  mkdir -p ${BACKUP_FOLDER}

  DB_NAME=$1
  echo "Create dump of database $DB_NAME from postgres"
  docker run \
  --network="honeur-net" \
  --rm \
  -e DB_NAME=$DB_NAME \
  -v "shared:/var/lib/shared:ro" \
  -v ${BACKUP_FOLDER}:/opt/database \
  postgres:9.6.18 bash -c 'set -e; source /var/lib/shared/honeur.env; export PGPASSWORD=${POSTGRES_PW}; cd /opt/database; pg_dump -h postgres -U postgres -f ${DB_NAME}.sql -d ${DB_NAME}'
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

read -p "Enter the name of the database to backup: " DATABASE_NAME
create_db_dump $DATABASE_NAME
tar_dump $DATABASE_NAME
