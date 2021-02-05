@echo off

echo Docker login, Make sure to use an account with access to the honeur docker hub images.
docker login

IF %ERRORLEVEL% EQU 0 (
    goto honeur_setup
) else (
    echo Failed to Login
    goto eof
)

:honeur_setup
echo Press [Enter] to start removing the existing HONEUR OMOP CDM DB container
pause>NUL

echo set COMPOSE_HTTP_TIMEOUT=300
set COMPOSE_HTTP_TIMEOUT=300

echo Stop previous HONEUR OMOP CDM DB container. Ignore errors when no such container exists.
echo stop postgres
docker stop postgres

echo Remove previous HONEUR OMOP CDM DB containers. Ignore errors when no such container exists.
echo remove postgres
docker rm postgres

echo Removing shared volume
docker volume rm shared

echo Success
echo Press [Enter] key to continue
pause>NUL

echo Downloading docker-compose.yml file.
curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/OMOPCDM/docker-compose.yml --output docker-compose.yml

docker volume create --name pgdata
docker volume create --name shared

docker-compose pull
docker-compose up

echo Removing downloaded files
rm docker-compose.yml

echo postgresql is available on localhost:5444
goto eof

:eof
echo Press [Enter] key to exit
pause>NUL