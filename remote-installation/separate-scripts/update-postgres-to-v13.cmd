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

docker network create feder8-net >/dev/null 2>&1 || true
docker pull harbor.honeur.org/library/install-script:2.0.0
docker run --rm -it --network feder8-net -v /var/run/docker.sock:/var/run/docker.sock harbor.honeur.org/library/install-script:2.0.0 feder8 init postgres