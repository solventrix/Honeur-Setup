docker stop honeur_ecrf_nginx
docker rm honeur_ecrf_nginx
docker stop honeur_ecrf_app
docker rm honeur_ecrf_app
docker stop ecrf-app
docker rm ecrf-app
docker stop honeur_ecrf_postgres
docker rm honeur_ecrf_postgres
docker stop ecrf-postgres
docker rm ecrf-postgres

docker volume rm postgres_data
docker volume rm static_volume

docker network rm honeur-net
