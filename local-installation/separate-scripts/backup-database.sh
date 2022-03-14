#!/usr/bin/env bash
set -e

DATABASE_NAME=OHDSI
BACKUP_FOLDER=${PWD}/backup

create_db_dump () {
  mkdir -p ${BACKUP_FOLDER}

  DB_NAME=$1
  echo "Create dump of database $DB_NAME from postgres"
  docker run \
  --network="feder8-net" \
  --rm \
  -e DB_NAME=$DB_NAME \
  -v "shared:/var/lib/shared:ro" \
  -v ${BACKUP_FOLDER}:/opt/database \
  postgres:13 bash -c 'set -e; source /var/lib/shared/honeur.env; export PGPASSWORD=${POSTGRES_PW}; export CURRENT_TIME=$(date "+%Y-%m-%d_%H-%M-%S"); pg_dump --clean --create -h postgres -U postgres -Fc ${DB_NAME} > /opt/database/${DB_NAME}_${CURRENT_TIME}.dump'
}

create_db_dump $DATABASE_NAME
