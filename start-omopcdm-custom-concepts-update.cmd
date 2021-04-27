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
echo Press [Enter] to start removing the existing omop-cdm-custom-concepts container
pause>NUL

echo Stop and remove previous omop-cdm-custom-concepts container. Ignore errors when such container exists.
echo stop omop-cdm-custom-concepts
docker stop omop-cdm-custom-concepts

echo remove omop-cdm-custom-concepts
docker rm omop-cdm-custom-concepts

echo Success
echo Press [Enter] key to continue
pause>NUL

echo Downloading docker-compose.yml file.
curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/ois/OMOPCDMCustomConcepts/docker-compose.yml --output docker-compose.yml

docker-compose pull
docker-compose up

echo Removing downloaded files
rm docker-compose.yml
rm -R setup-conf

echo success
goto eof


:eof
echo Press [Enter] key to exit
pause>NUL