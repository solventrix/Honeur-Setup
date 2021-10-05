@echo off

SET DATABASE_NAME=opal

SET /p DATABASE_BACKUP_FILE="Please enter the full path of the backup file: "
:while-backup-file-not-correct
if "%DATABASE_BACKUP_FILE%" == "" (
   echo The backup file cannot be empty
   SET /p DATABASE_BACKUP_FILE="Please enter the full path of the backup file: "
   goto :while-backup-file-not-correct
)

if exist %DATABASE_BACKUP_FILE% (
    rem file exists
) else (
    echo %DATABASE_BACKUP_FILE% not found!
    exit 1
)

SET /p POSTGRES_PASSWORD="Please enter the password for Postgres: "
:while-postgres-password-not-correct
if "%POSTGRES_PASSWORD%" == "" (
   echo The password cannot be empty
   SET /p POSTGRES_PASSWORD="Please enter the password for Postgres: "
   goto :while-postgres-password-not-correct
)

echo Restore database %DATABASE_NAME%
docker run --network="honeur-net" --rm -e DB_NAME=%DATABASE_NAME% -e PGPASSWORD=%POSTGRES_PASSWORD% -v %DATABASE_BACKUP_FILE%:/opt/database/backup.dump postgres:13.0-alpine sh -c "set -e; cd /opt/database; PGPASSWORD=${PGPASSWORD} pg_restore --clean -h honeur_ecrf_postgres -U postgres -d ${DB_NAME} /opt/database/backup.dump"
