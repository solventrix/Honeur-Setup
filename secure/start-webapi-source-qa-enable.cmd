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

echo Stop previous containers. Ignore errors when no webapi-source-qa-enable container exist yet.
echo stop webapi-source-qa-enable
docker stop webapi-source-qa-enable

echo Removing previous containers. This can give errors when no webapi-source-qa-enable container exist yet.
echo remove webapi-source-qa-enable
docker rm webapi-source-qa-enable

echo Succes
echo Press [Enter] key to continue
pause>NUL

echo Creating folder setup-conf
mkdir setup-conf
echo Downloading docker-compose.yml file.
curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/secure/WebAPIDBQASourceCreation/docker-compose.yml --output docker-compose.yml
echo Downloading setup.yml file inside setup-conf folder
curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/secure/WebAPIDBQASourceCreation/setup-conf/setup.yml --output setup-conf/setup.yml

docker-compose rm -f
docker-compose pull
docker-compose up

echo success
goto eof


:eof
echo Press [Enter] key to exit
pause>NUL