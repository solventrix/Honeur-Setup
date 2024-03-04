#!/usr/bin/env bash

REGISTRY=harbor.honeur.org
REPOSITORY=honeur
DB_HOST=
DB_PORT=5432
DB_DATABASE_NAME=OHDSI
DB_ADMIN_USERNAME=postgres
DB_ADMIN_PASSWORD=
DB_OMOPCDM_SCHEMA=omopcdm
DB_RESULTS_SCHEMA=results
OMOP_CDM_VERSION=5.4

echo "Docker login"
docker login $REGISTRY

echo "Create database roles and users"
docker run --rm --name ohdsi-add-database-users \
--env DB_HOST=$DB_HOST --env DB_PORT=$DB_PORT --env FEDER8_ORGANIZATION_NAME=HONEUR \
--env POSTGRES_ROOT_USERNAME$DB_ADMIN_USERNAME --env POSTGRES_ROOT_PASSWORD=$DB_ADMIN_PASSWORD \
--env WEBAPI_USER_PW=ohdsi_app_user --env WEBAPI_ADMIN_PW=ohdsi_admin_user \
--env FEDER8_USER_USER=feder8 --env FEDER8_USER_PW=feder8 \
--env FEDER8_ADMIN_USER=feder8_admin --env FEDER8_ADMIN_PW=feder8_admin \
$REGISTRY/$REPOSITORY/postgres:ohdsi-add-database-users-2.0.0

echo "Create OMOP CDM database 'OHDSI'"
docker run --rm --name ohdsi-add-database \
--env DB_HOST=$DB_HOST --env DB_PORT=$DB_PORT --env POSTGRES_ROOT_USERNAME=$DB_ADMIN_USERNAME --env POSTGRES_ROOT_PASSWORD=$DB_ADMIN_PASSWORD \
$REGISTRY/$REPOSITORY/postgres:ohdsi-add-database-2.0.0

echo "Enable Postgres extensions"
docker run --rm --name enable-extensions \
--env DB_HOST=$DB_HOST --env DB_PORT=$DB_PORT --env DB_DATABASE_NAME=$DB_DATABASE_NAME \
--env POSTGRES_USER=$DB_ADMIN_USERNAME --env POSTGRES_PW=$DB_ADMIN_PASSWORD \
$REGISTRY/$REPOSITORY/postgres:enable-extensions-2.0.0

echo "Create CDM schema '$DB_OMOPCDM_SCHEMA'"
docker run --rm --name omopcdm-initialize-schema \
--env DB_HOST=$DB_HOST --env DB_PORT=$DB_PORT --env DB_DATABASE_NAME=$DB_DATABASE_NAME \
--env DB_OMOPCDM_SCHEMA=$DB_OMOPCDM_SCHEMA --env POSTGRES_PW=$DB_ADMIN_PASSWORD \
--env WEBAPI_ADMIN_USER=$DB_ADMIN_USERNAME --env WEBAPI_ADMIN_PW=$DB_ADMIN_PASSWORD \
--env FEDER8_ADMIN_USERNAME=feder8_admin \
$REGISTRY/$REPOSITORY/postgres-omopcdm-initialize-schema:$OMOP_CDM_VERSION-2.0.2

echo "Create results schema"
docker run --rm --name results-initialize-schema \
--env DB_HOST=$DB_HOST --env DB_PORT=$DB_PORT --env DB_DATABASE_NAME=$DB_DATABASE_NAME \
--env DB_RESULTS_SCHEMA=$DB_RESULTS_SCHEMA \
--env WEBAPI_ADMIN_USER=$DB_ADMIN_USERNAME --env WEBAPI_ADMIN_PW=$DB_ADMIN_PASSWORD \
--env FEDER8_ADMIN_USERNAME=feder8_admin --env POSTGRES_PW=$DB_ADMIN_PASSWORD \
$REGISTRY/$REPOSITORY/postgres-results-initialize-schema:2.0.3

echo "Create scratch schema"
docker run --rm --name scratch-initialize-schema \
--env DB_HOST=$DB_HOST --env DB_PORT=$DB_PORT --env DB_DATABASE_NAME=$DB_DATABASE_NAME \
--env DB_SCRATCH_SCHEMA=scratch --env POSTGRES_PW=$DB_ADMIN_PASSWORD \
--env WEBAPI_ADMIN_USER=$DB_ADMIN_USERNAME --env WEBAPI_ADMIN_PW=$DB_ADMIN_PASSWORD \
--env FEDER8_ADMIN_USERNAME=feder8_admin --env FEDER8_ORGANIZATION_NAME=HONEUR \
$REGISTRY/$REPOSITORY/postgres:scratch-initialize-schema-2.0.1

echo "Update vocabularies"
docker run --rm --name omopcdm-update-vocabulary \
--env DB_HOST=$DB_HOST --env DB_PORT=$DB_PORT --env DB_DATABASE_NAME=$DB_DATABASE_NAME \
--env DB_OMOPCDM_SCHEMA=$DB_OMOPCDM_SCHEMA \
--env WEBAPI_ADMIN_USER=$DB_ADMIN_USERNAME --env WEBAPI_ADMIN_PW=$DB_ADMIN_PASSWORD \
$REGISTRY/$REPOSITORY/postgres-omopcdm-update-vocabulary:2.1.0

echo "Update custom concepts for HONEUR"
docker run --rm --name omopcdm-update-custom-concepts \
--env DB_HOST=$DB_HOST --env DB_PORT=$DB_PORT --env DB_DATABASE_NAME=$DB_DATABASE_NAME \
--env DB_OMOPCDM_SCHEMA=$DB_OMOPCDM_SCHEMA \
--env WEBAPI_ADMIN_USER=$DB_ADMIN_USERNAME --env WEBAPI_ADMIN_PW=$DB_ADMIN_PASSWORD \
$REGISTRY/$REPOSITORY/postgres-omopcdm-update-custom-concepts:latest

echo "Add base primary keys"
docker run --rm --name  omopcdm-add-base-primary-keys \
--env DB_HOST=$DB_HOST --env DB_PORT=$DB_PORT --env DB_DATABASE_NAME=$DB_DATABASE_NAME \
--env DB_OMOPCDM_SCHEMA=$DB_OMOPCDM_SCHEMA \
--env WEBAPI_ADMIN_USER=$DB_ADMIN_USERNAME --env WEBAPI_ADMIN_PW=$DB_ADMIN_PASSWORD \
$REGISTRY/$REPOSITORY/postgres-omopcdm-add-base-primary-keys:$OMOP_CDM_VERSION-2.0.1

echo "Add base indexes"
docker run --rm --name  omopcdm-add-base-indexes \
--env DB_HOST=$DB_HOST --env DB_PORT=$DB_PORT --env DB_DATABASE_NAME=$DB_DATABASE_NAME \
--env DB_OMOPCDM_SCHEMA=$DB_OMOPCDM_SCHEMA \
--env WEBAPI_ADMIN_USER=$DB_ADMIN_USERNAME --env WEBAPI_ADMIN_PW=$DB_ADMIN_PASSWORD \
$REGISTRY/$REPOSITORY/postgres-omopcdm-add-base-indexes:$OMOP_CDM_VERSION-2.0.1

echo "Rebuild concept hierarchy"
docker run --rm --name results-rebuild-concept-hierarchy \
--env DB_HOST=$DB_HOST --env DB_PORT=$DB_PORT --env DB_DATABASE_NAME=$DB_DATABASE_NAME \
--env DB_OMOPCDM_SCHEMA=$DB_OMOPCDM_SCHEMA \
--env WEBAPI_ADMIN_USER=$DB_ADMIN_USERNAME --env WEBAPI_ADMIN_PW=$DB_ADMIN_PASSWORD \
$REGISTRY/$REPOSITORY/postgres:results-rebuild-concept-hierarchy-2.0.2
