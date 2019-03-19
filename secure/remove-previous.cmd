@echo off

echo stop webapi
docker stop webapi
echo stop zeppelin
docker stop zeppelin
echo stop user-mgmt
docker stop user-mgmt
echo stop postgres
docker stop postgres

echo remove webapi
docker rm webapi
echo remove zeppelin
docker rm zeppelin
echo remove user-mgmt
docker rm user-mgmt
echo remove postgres
docker rm postgres

echo Press [Enter] key to exit
pause>NUL