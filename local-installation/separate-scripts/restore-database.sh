#!/usr/bin/env bash
set -e

DATABASE_NAME=OHDSI

DATABASE_BACKUP_FILE=
read -p "Please enter the absolute path of the backup file (.dump) to restore: " DATABASE_BACKUP_FILE
while [[ "$DATABASE_BACKUP_FILE" == "" ]]; do
    echo "The backup file path cannot be empty"
    read -p "Please enter the absolute path of the backup file (.dump) to restore: " DATABASE_BACKUP_FILE
done

if [ -f "$DATABASE_BACKUP_FILE" ]; then
    echo "$DATABASE_BACKUP_FILE found."
else
    echo "$DATABASE_BACKUP_FILE not found!"
    exit 1
fi

echo "Restore database $DATABASE_NAME"
docker run \
--network="feder8-net" \
--rm \
-e DB_NAME=$DATABASE_NAME \
-v ${DATABASE_BACKUP_FILE}:/opt/database/backup.dump \
-v shared:/var/lib/shared
postgres:13 bash -c 'set -e; source /var/lib/shared/honeur.env; export PGPASSWORD=${POSTGRES_PW}; pg_restore --clean -h postgres -U postgres -d ${DB_NAME} /opt/database/backup.dump'
