@echo off

DATABASE_NAME=postgres
BACKUP_FOLDER=%cd%\backup

SET /p POSTGRES_PASSWORD="Please enter the password for Postgres: "
:while-postgres-password-not-correct
if "%POSTGRES_PASSWORD%" == "" (
   echo The password cannot be empty
   SET /p POSTGRES_PASSWORD="Please enter the password for Postgres: "
   goto :while-postgres-password-not-correct
)

Rem create database dump
IF not exist %BACKUP_FOLDER% ( mkdir %BACKUP_FOLDER% && echo %BACKUP_FOLDER% created )
echo Create dump of database %DATABASE_NAME% from postgres.  Backup file will be stored under %BACKUP_FOLDER%
docker run \
--network="honeur-net" \
--rm \
-e DB_NAME=%DATABASE_NAME% \
-e PGPASSWORD=%POSTGRES_PASSWORD% \
-v ${BACKUP_FOLDER}:/opt/database \
postgres:13.0-alpine sh -c 'set -e; cd /opt/database; PGPASSWORD=${PGPASSWORD} pg_dump -h honeur_ecrf_postgres -U postgres -f ${DB_NAME}.sql -d ${DB_NAME}; export CURRENT_TIME=$(date "+%Y-%m-%d_%H-%M-%S"); tar -czf /opt/database/${DB_NAME}_${CURRENT_TIME}.tar.gz ${DB_NAME}.sql; rm ${DB_NAME}.sql'
