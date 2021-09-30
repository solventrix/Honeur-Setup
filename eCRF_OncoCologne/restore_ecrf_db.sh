#!/usr/bin/env bash
set -e

if [ -z "$1" ]
  then
    echo "Please specify the file to restore"
    exit 1
fi

DATABASE_BACKUP_FILE=$1
CURRENT_TIME=$(date "+%Y_%m_%d_%H_%M_%S")
RESTORE_FOLDER=${PWD}/restore/${CURRENT_TIME}

POSTGRES_PASSWORD=
read -p "Please enter the password for Postgres: " POSTGRES_PASSWORD
while [[ "$POSTGRES_PASSWORD" == "" ]]; do
    echo "The password cannot be empty"
    read -p "Please enter the password for Postgres: " POSTGRES_PASSWORD
done

mkdir -p ${RESTORE_FOLDER}

export LANG=en_US.UTF-8
export LC_ALL=$LANG
tar -C ${RESTORE_FOLDER} -zxvf ${DATABASE_BACKUP_FILE}

echo "remove old database container"
docker stop honeur_ecrf_postgres
docker rm honeur_ecrf_postgres
docker volume rm postgres_data
docker volume create postgres_data
echo "re-create database container"
docker run -d --name honeur_ecrf_postgres --network honeur-net --volume postgres_data:/var/lib/postgresql/data --env POSTGRES_PASSWORD=$POSTGRES_PASSWORD --restart=always -p 5432:5432 harbor.honeur.org/ecrf/oncocologne/postgres:0.2
sleep 5s

for sql_script in ${RESTORE_FOLDER}/*.sql; do
    sql_script_name=$(basename -- "$sql_script")
    DB_NAME="${sql_script_name%%.*}"
    echo "Restore database $DB_NAME"
    cat $sql_script | docker exec -i honeur_ecrf_postgres bash -c "PGPASSWORD=${POSTGRES_PASSWORD} psql -U postgres -d $DB_NAME"
done

rm -rf ${RESTORE_FOLDER}