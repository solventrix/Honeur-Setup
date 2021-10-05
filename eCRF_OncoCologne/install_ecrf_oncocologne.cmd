@echo off

SET DATABASE_NAME=opal

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
docker pull harbor.honeur.org/ecrf/oncocologne/postgres:0.2
docker pull harbor.honeur.org/ecrf/oncocologne/app:0.2
docker pull harbor.honeur.org/ecrf/oncocologne/nginx:0.2

echo "create network honeur-net"
docker network create honeur-net

echo "create volumes postgres_data and static_volume"
docker volume create postgres_data
docker volume create static_volume

echo "create database container"
docker run -d --name honeur_ecrf_postgres --network honeur-net --volume postgres_data:/var/lib/postgresql/data --env POSTGRES_PASSWORD=%POSTGRES_PASSWORD% --restart=always harbor.honeur.org/ecrf/oncocologne/postgres:0.2
TIMEOUT 10

echo "initialize eCRF database"
docker run -d --name honeur_ecrf_app --network honeur-net --volume static_volume:/code/entrytool/assets --env OPAL_SUPER_USER_PASSWORD=%OPAL_SUPER_USER_PASSWORD% --env OPAL_DB_USER=postgres --env OPAL_DB_PASSWORD=%POSTGRES_PASSWORD% --env OPAL_DB_NAME=%DATABASE_NAME% --env OPAL_DB_HOST=honeur_ecrf_postgres --env OPAL_DB_PORT=5432 --env OPAL_FLUSH_DB=true --env OPAL_ENABLE_USER_DB=false --env OPAL_ENABLE_LDAP=false harbor.honeur.org/ecrf/oncocologne/app:0.2 gunicorn -b 0.0.0.0:8000 entrytool.wsgi
TIMEOUT 60
echo "create eCRF app container"
docker stop honeur_ecrf_app
docker rm honeur_ecrf_app
docker run -d --name honeur_ecrf_app --network honeur-net --volume static_volume:/code/entrytool/assets --env OPAL_SUPER_USER_PASSWORD=%OPAL_SUPER_USER_PASSWORD% --env OPAL_DB_USER=postgres --env OPAL_DB_PASSWORD=%POSTGRES_PASSWORD% --env OPAL_DB_NAME=%DATABASE_NAME% --env OPAL_DB_HOST=honeur_ecrf_postgres --env OPAL_DB_PORT=5432 --env OPAL_FLUSH_DB=false --env OPAL_ENABLE_USER_DB=false --env OPAL_ENABLE_LDAP=false --restart=always harbor.honeur.org/ecrf/oncocologne/app:0.2 gunicorn -b 0.0.0.0:8000 entrytool.wsgi
TIMEOUT 15

echo "create nginx container"
docker run -d --name honeur_ecrf_nginx --network honeur-net -v static_volume:/code/entrytool/assets --restart=always -p 80:80 harbor.honeur.org/ecrf/oncocologne/nginx:0.2
