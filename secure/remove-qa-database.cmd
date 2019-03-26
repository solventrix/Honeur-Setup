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
echo stop webapi-source-qa-disable
docker stop webapi-source-qa-disable

echo Removing previous containers. This can give errors when no containers exist yet.
echo remove postgres-qa
docker rm postgres-qa
echo remove webapi-source-qa-disable
docker rm webapi-source-qa-disable

echo Succes
echo Press [Enter] key to continue
pause>NUL

echo Creating folder setup-conf
mkdir setup-conf
echo Downloading docker-compose.yml file.
curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/secure/WebAPIDBQASourceDeletion/docker-compose.yml --output docker-compose.yml
echo Downloading setup.yml file inside setup-conf folder
curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/secure/WebAPIDBQASourceDeletion/setup-conf/setup.yml --output setup-conf/setup.yml

docker-compose pull
docker-compose up -d

echo Removing downloaded files
rm docker-compose.yml
rm -R setup-conf

goto eof

:eof
echo Press [Enter] key to exit
pause>NUL