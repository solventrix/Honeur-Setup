set -e

docker volume create new-pgdata

docker stop postgres || true
docker rm postgres || true
docker run --rm --name postgres -e POSTGRES_PASSWORD=postgres -v new-pgdata:/var/lib/postgresql/data -d postgres:13

sleep 20
docker stop postgres

docker run --rm -v pgdata:/var/lib/postgresql/9.6/data -v new-pgdata:/var/lib/postgresql/13/data tianon/postgres-upgrade:9.6-to-13

docker volume remove pgdata
docker volume create pgdata

docker run --rm -it -v new-pgdata:/from -v pgdata:/to alpine ash -c "cd /from ; cp -av . /to"

docker volume remove new-pgdata

docker pull harbor-dev.honeur.org/library/install-script:2.0.1
docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock harbor-dev.honeur.org/library/install-script:2.0.1 feder8 init postgres
