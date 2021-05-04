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

echo Stop previous containers. Ignore errors when no omop-indexes-and-constraints container exist yet.
echo stop omop-indexes-and-constraints
docker stop omop-indexes-and-constraints

echo Removing previous containers. This can give errors when no omop-indexes-and-constraints container exist yet.
echo remove omop-indexes-and-constraints
docker rm omop-indexes-and-constraints

echo Succes
echo Press [Enter] key to continue
pause>NUL

echo Creating folder setup-conf
mkdir setup-conf
echo Downloading docker-compose.yml file.
curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/OMOPCDMDBIndexesAndContraints/docker-compose.yml --output docker-compose.yml

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