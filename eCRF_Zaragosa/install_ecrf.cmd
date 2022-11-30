@echo off
set -e

SET REGISTRY=harbor.honeur.org
SET SITE=zaragosa
SET REPOSITORY=ecrf/%SITE%
SET VERSION=0.2
SET NETWORK=feder8-net
SET DATABASE_NAME=postgres

SET /p POSTGRES_PASSWORD="Please enter a strong password for Postgres: "
:while-postgres-password-not-correct
if "%POSTGRES_PASSWORD%" == "" (
   echo The password cannot be empty
   SET /p POSTGRES_PASSWORD="Please enter a strong password for Postgres: "
   goto :while-postgres-password-not-correct
)

SET /p OPAL_SUPER_USER_PASSWORD="Please enter a strong password for the 'super' user of the eCRF tool: "
:while-ecrf-password-not-correct
if "%POSTGRES_PASSWORD%" == "" (
   echo The password cannot be empty
   SET /p OPAL_SUPER_USER_PASSWORD="Please enter a strong password for the 'super' user of the eCRF tool: "
   goto :while-ecrf-password-not-correct
)

echo "pull docker images"
docker pull %REGISTRY%/%REPOSITORY%/postgres:%VERSION%
docker pull %REGISTRY%/%REPOSITORY%/app:%VERSION%

echo "create volume postgres_data"
docker volume create postgres_data

echo "create database container"
docker run -d --name ecrf-postgres --network %NETWORK% -p 5432:5432 --volume postgres_data:/var/lib/postgresql/data --env POSTGRES_PASSWORD=%POSTGRES_PASSWORD% --restart=always %REGISTRY%/%REPOSITORY%/postgres:%VERSION%
echo "waiting on database container..."
TIMEOUT 10

echo "initialize eCRF database"
docker run -d --name ecrf-app --network %NETWORK% --volume static_volume:/code/entrytool/assets --env OPAL_SUPER_USER_PASSWORD=%OPAL_SUPER_USER_PASSWORD% --env OPAL_DB_USER=postgres --env OPAL_DB_PASSWORD=%POSTGRES_PASSWORD% --env OPAL_DB_NAME=%DATABASE_NAME% --env OPAL_DB_HOST=ecrf-postgres --env OPAL_DB_PORT=5432 --env OPAL_FLUSH_DB=true --env OPAL_ENABLE_USER_DB=false --env OPAL_ENABLE_LDAP=false %REGISTRY%/%REPOSITORY%/app:%VERSION% gunicorn -b 0.0.0.0:8000 entrytool.wsgi
TIMEOUT 90

echo "create eCRF app container"
docker stop ecrf-app
docker rm ecrf-app
docker run -d --name ecrf-app --network %NETWORK% --volume static_volume:/code/entrytool/assets --env OPAL_SUPER_USER_PASSWORD=%OPAL_SUPER_USER_PASSWORD% --env OPAL_DB_USER=postgres --env OPAL_DB_PASSWORD=%POSTGRES_PASSWORD% --env OPAL_DB_NAME=%DATABASE_NAME% --env OPAL_DB_HOST=ecrf-postgres --env OPAL_DB_PORT=5432 --env OPAL_FLUSH_DB=false --env OPAL_ENABLE_USER_DB=false --env OPAL_ENABLE_LDAP=false --restart=always %REGISTRY%/%REPOSITORY%/app:%VERSION% gunicorn -b 0.0.0.0:8000 entrytool.wsgi
TIMEOUT 20
