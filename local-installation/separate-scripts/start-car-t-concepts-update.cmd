@ECHO off

echo "Log into Harbor image repository"
docker login harbor.honeur.org

docker run --rm --name omopcdm-update-car-t --network feder8-net -v shared:/var/lib/shared harbor.honeur.org/honeur/postgres-omopcdm-update-car-t:1.0
