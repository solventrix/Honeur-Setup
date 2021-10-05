#!/usr/bin/env bash
set -e

DATABASE_NAME=opal

DATABASE_BACKUP_FILE=
read -p "Please enter the absolute path of the backup file to restore: " DATABASE_BACKUP_FILE
while [[ "$DATABASE_BACKUP_FILE" == "" ]]; do
    echo "The backup file path cannot be empty"
    read -p "Please enter the absolute path of the backup file to restore: " DATABASE_BACKUP_FILE
done

if [ -f "$DATABASE_BACKUP_FILE" ]; then
    echo "$DATABASE_BACKUP_FILE found."
else
    echo "$DATABASE_BACKUP_FILE not found!"
    exit 1
fi

POSTGRES_PASSWORD=
read -p "Please enter the password for Postgres: " POSTGRES_PASSWORD
while [[ "$POSTGRES_PASSWORD" == "" ]]; do
    echo "The password cannot be empty"
    read -p "Please enter the password for Postgres: " POSTGRES_PASSWORD
done

echo "Restore database $DATABASE_NAME"
docker run \
--network="honeur-net" \
--rm \
-e DB_NAME=$DATABASE_NAME \
-e PGPASSWORD=$POSTGRES_PASSWORD \
-v ${DATABASE_BACKUP_FILE}:/opt/database/backup.dump \
postgres:13.0-alpine sh -c 'set -e; cd /opt/database; PGPASSWORD=${PGPASSWORD} pg_restore --clean -h honeur_ecrf_postgres -U postgres -d ${DB_NAME} /opt/database/backup.dump'
