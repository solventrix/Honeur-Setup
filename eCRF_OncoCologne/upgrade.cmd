@echo off

SET DATABASE_NAME=opal
SET BACKUP_FOLDER=%cd%\backup

SET REGISTRY=harbor.honeur.org
SET SITE=oncocologne
SET REPOSITORY=ecrf/%SITE%
SET TAG=0.2.1
SET NETWORK=honeur-net


SET /p POSTGRES_PASSWORD="Please enter the password for Postgres: "
:while-postgres-password-not-correct
if "%POSTGRES_PASSWORD%" == "" (
   echo The password cannot be empty
   SET /p POSTGRES_PASSWORD="Please enter the password for Postgres: "
   goto :while-postgres-password-not-correct
)

SET /p OPAL_SUPER_USER_PASSWORD="Please enter the password for the 'super' user of the eCRF tool: "
:while-ecrf-password-not-correct
if "%POSTGRES_PASSWORD%" == "" (
   echo The password cannot be empty
   SET /p OPAL_SUPER_USER_PASSWORD="Please enter the password for the 'super' user of the eCRF tool: "
   goto :while-ecrf-password-not-correct
)

echo "Take database backup"
IF not exist %BACKUP_FOLDER% ( mkdir %BACKUP_FOLDER% && echo %BACKUP_FOLDER% created )
echo Create dump of database %DATABASE_NAME% from postgres.  Backup file will be stored under %BACKUP_FOLDER%
docker run --network=%NETWORK% --rm -e DB_NAME=%DATABASE_NAME% -e PGPASSWORD=%POSTGRES_PASSWORD% -v %BACKUP_FOLDER%:/opt/database postgres:13.0-alpine sh -c "set -e; cd /opt/database; export CURRENT_TIME=$(date "+%%Y-%%m-%%d_%%H-%%M-%%S"); PGPASSWORD=${PGPASSWORD} pg_dump -h honeur_ecrf_postgres -U postgres -Fc ${DB_NAME} > /opt/database/${DB_NAME}_${CURRENT_TIME}.dump"


echo "Stop running eCRF app"
docker stop honeur_ecrf_app > nul 2> nul
docker rm honeur_ecrf_app > nul 2> nul

echo "Stop running NGINX"
docker stop honeur_ecrf_nginx > nul 2> nul
docker rm honeur_ecrf_nginx > nul 2> nul

echo "Recreate static volume"
docker volume rm static_volume > nul 2> nul
docker volume create static_volume

echo "Install new eCRF app"
docker pull %REGISTRY%/%REPOSITORY%/app:%TAG%
docker run -d --name honeur_ecrf_app --network %NETWORK% --volume static_volume:/code/entrytool/assets --env OPAL_SUPER_USER_PASSWORD=%OPAL_SUPER_USER_PASSWORD% --env OPAL_DB_USER=postgres --env OPAL_DB_PASSWORD=%POSTGRES_PASSWORD% --env OPAL_DB_NAME=%DATABASE_NAME% --env OPAL_DB_HOST=honeur_ecrf_postgres --env OPAL_DB_PORT=5432 --env OPAL_FLUSH_DB=false --env OPAL_ENABLE_USER_DB=false --env OPAL_ENABLE_LDAP=false --restart=always %REGISTRY%/%REPOSITORY%/app:%TAG% gunicorn -b 0.0.0.0:8000 entrytool.wsgi
TIMEOUT 20

echo "Install new NGINX"
docker run -d --name honeur_ecrf_nginx --network %NETWORK% -v static_volume:/code/entrytool/assets --restart=always -p 80:80 %REGISTRY%/%REPOSITORY%/nginx:%TAG%

echo "Upgrade successfully completed"