@echo off

echo "Docker login"
docker login harbor.honeur.org

echo "Initialize new OMOP CDM 5.4 database schema"
SET SCHEMA=omopcdm54
docker run --rm --name omopcdm-initialize-schema -v shared:/var/lib/shared --env DB_HOST=postgres --env DB_PORT=5432 --env DB_DATABASE_NAME=OHDSI --env DB_OMOPCDM_SCHEMA=%SCHEMA% --env FEDER8_ADMIN_USERNAME=feder8_admin --network feder8-net harbor.honeur.org/honeur/postgres-omopcdm-initialize-schema:5.4-2.0.2

echo "Load vocabularies"
docker run --rm --name omopcdm-update-vocabulary -v shared:/var/lib/shared --env DB_HOST=postgres --env DB_PORT=5432 --env DB_OMOPCDM_SCHEMA=%SCHEMA% --network feder8-net harbor.honeur.org/honeur/postgres-omopcdm-update-vocabulary:2.1.0

echo "Load custom concepts"
docker run --rm --name omopcdm-update-custom-concepts -v shared:/var/lib/shared --env DB_HOST=postgres --env DB_PORT=5432 --env DB_DATABASE_NAME=OHDSI --env DB_OMOPCDM_SCHEMA=%SCHEMA% --network feder8-net harbor.honeur.org/honeur/postgres-omopcdm-update-custom-concepts:latest

echo "Add primary keys"
docker run --rm --name  omopcdm-add-base-primary-keys -v shared:/var/lib/shared --env DB_HOST=postgres --env DB_PORT=5432 --env DB_OMOPCDM_SCHEMA=%SCHEMA% --network feder8-net harbor.honeur.org/honeur/postgres-omopcdm-add-base-primary-keys:5.4-2.0.1

echo "Add indexes"
docker run --rm --name  omopcdm-add-base-indexes -v shared:/var/lib/shared --env DB_HOST=postgres --env DB_PORT=5432 --env DB_OMOPCDM_SCHEMA=%SCHEMA% --network feder8-net harbor.honeur.org/honeur/postgres-omopcdm-add-base-indexes:5.4-2.0.1

echo "Schema '%SCHEMA%' created"