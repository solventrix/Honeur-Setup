@ECHO off

SET TAG=2.0.22
SET REGISTRY=harbor.honeur.org

docker volume create new-pgdata

docker stop postgres
docker rm postgres
docker run --rm --name postgres -e POSTGRES_PASSWORD=postgres -v new-pgdata:/var/lib/postgresql/data -d postgres:13

sleep 20
docker stop postgres

docker run --rm -v pgdata:/var/lib/postgresql/9.6/data -v new-pgdata:/var/lib/postgresql/13/data tianon/postgres-upgrade:9.6-to-13

docker volume remove pgdata
docker volume create pgdata

docker run --rm -it -v new-pgdata:/from -v pgdata:/to alpine ash -c "cd /from ; cp -av . /to"

docker volume remove new-pgdata

docker pull %REGISTRY%/library/install-script:%TAG%
docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock %REGISTRY%/library/install-script:%TAG% feder8 init postgres
