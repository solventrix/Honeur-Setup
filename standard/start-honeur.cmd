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
echo stop webapi
docker stop webapi
echo stop zeppelin
docker stop zeppelin
echo stop postgres
docker stop postgres

echo Removing previous containers. This can give errors when no containers exist yet.
echo remove webapi
docker rm webapi
echo remove zeppelin
docker rm zeppelin
echo remove postgres
docker rm postgres

echo Succes
echo Press [Enter] key to continue
pause>NUL

echo Downloading docker-compose.yml file.
curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/standard/docker-compose.yml --output docker-compose.yml

set /p honeur_host_machine="Enter the FQDN(Fully Qualified Domain Name eg. www.example.com) or public IP address(eg. 125.24.44.18) of the host machine. Use localhost to for testing [localhost]: " || SET honeur_host_machine=localhost
set /p honeur_zeppelin_logs="Enter the directory where the zeppelin logs will kept on the host machine [./zeppelin/logs]: " || SET honeur_zeppelin_logs=./zeppelin/logs
set /p honeur_zeppelin_notebooks="Enter the directory where the zeppelin notebooks will kept on the host machine [./zeppelin/notebook]: " || SET honeur_zeppelin_notebooks=./zeppelin/notebook

sed -i -e "s@- \"BACKEND_HOST=http://localhost@- \"BACKEND_HOST=http://%honeur_host_machine%@g" docker-compose.yml
sed -i -e "s@- ./zeppelin/logs@- %honeur_zeppelin_logs%@g" docker-compose.yml
sed -i -e "s@- ./zeppelin/notebook@- %honeur_zeppelin_notebooks%@g" docker-compose.yml

docker volume create --name pgdata
docker volume create --name shared

docker-compose pull
docker-compose up -d

echo Removing downloaded files
rm docker-compose.yml

echo postgresql is available on %honeur_host_machine%:5444
echo webapi/atlas is available on http://%honeur_host_machine%:8080/webapi and http://%honeur_host_machine%:8080/atlas respectively
echo Zeppelin is available on http://%honeur_host_machine%:8082
echo Zeppelin logs are available in directory %honeur_zeppelin_logs%
echo Zeppelin notebooks are available in directory %honeur_zeppelin_notebooks%
goto eof


:eof
echo Press [Enter] key to exit
pause>NUL