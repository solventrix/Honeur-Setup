docker stop ecrf-app
docker rm ecrf-app
docker stop ecrf-postgres
docker rm ecrf-postgres

docker volume rm postgres_data
