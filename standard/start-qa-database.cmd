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
echo Press [Enter] to start removing the existing containers
pause>NUL

echo Stop previous containers. Ignore errors when no containers exist yet.
echo stop postgres-qa
docker stop postgres-qa
echo stop webapi-source-qa-enable
docker stop webapi-source-qa-enable

echo Removing previous containers. This can give errors when no containers exist yet.
echo remove postgres-qa
docker rm postgres-qa
echo remove webapi-source-qa-enable
docker rm webapi-source-qa-enable

echo Succes
echo Press [Enter] key to continue
pause>NUL

echo Creating folder setup-conf
mkdir setup-conf
echo Downloading docker-compose.yml file.
curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/standard/WebAPIDBQASourceCreation/docker-compose.yml --output docker-compose.yml
echo Downloading setup.yml file inside setup-conf folder
curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/standard/WebAPIDBQASourceCreation/setup-conf/setup.yml --output setup-conf/setup.yml

docker volume create --name pgdata-qa
docker volume create --name shared-qa

docker-compose pull
docker-compose up -d

echo postgresql is available on localhost:5445
goto eof


:eof
echo Press [Enter] key to exit
pause>NUL