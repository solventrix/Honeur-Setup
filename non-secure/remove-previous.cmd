@echo off

echo stop webapi
docker stop webapi
echo stop zeppelin
docker stop zeppelin
echo stop postgres
docker stop postgres

echo remove webapi
docker rm webapi
echo remove zeppelin
docker rm zeppelin
echo remove postgres
docker rm postgres

echo Press [Enter] key to exit
pause>NUL