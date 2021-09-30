@echo off

DATABASE_NAME=postgres

SET /p DATABASE_BACKUP_FILE="Please enter the full path of the backup file: "
:while-backup-file-not-correct
if "%DATABASE_BACKUP_FILE%" == "" (
   echo The backup file cannot be empty
   SET /p DATABASE_BACKUP_FILE="Please enter the full path of the backup file: "
   goto :while-backup-file-not-correct
)

SET /p POSTGRES_PASSWORD="Please enter the password for Postgres: "
:while-postgres-password-not-correct
if "%POSTGRES_PASSWORD%" == "" (
   echo The password cannot be empty
   SET /p POSTGRES_PASSWORD="Please enter the password for Postgres: "
   goto :while-postgres-password-not-correct
)

CURRENT_TIME=%time%
RESTORE_FOLDER=%cd%\restore\%TIME%

mkdir %RESTORE_FOLDER%

echo "remove old database container"
docker stop honeur_ecrf_postgres
docker rm honeur_ecrf_postgres
docker volume rm postgres_data
docker volume create postgres_data
echo "re-create database container"
docker run -d --name honeur_ecrf_postgres --network honeur-net --volume postgres_data:/var/lib/postgresql/data --env POSTGRES_PASSWORD=%POSTGRES_PASSWORD% --restart=always -p 5432:5432 harbor.honeur.org/ecrf/oncocologne/postgres:0.2
TIMEOUT 5

echo "Restore database $DB_NAME"
type %DATABASE_BACKUP_FILE% | docker exec -i honeur_ecrf_postgres bash -c "PGPASSWORD=%POSTGRES_PASSWORD% psql -U postgres -d %DATABASE_NAME%"

rmdir /s  ${RESTORE_FOLDER}
