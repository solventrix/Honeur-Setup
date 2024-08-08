#!/usr/bin/env bash
set -ex

REGISTRY=harbor.honeur.org
REPOSITORY=etl-det
IMAGE=etl
VERSION=v1.1.2
TAG=$VERSION

echo "Set privileges for user 'feder8_admin'"
docker exec -it postgres psql -U postgres -d OHDSI -c "ALTER USER feder8_admin WITH SUPERUSER;"

# ENV VARIABLES 
ETL_VERSION=$VERSION
SOURCE_RELEASE_DATE="2024/08/08" #to define by the user 
VERBOSITY_LEVEL=DEBUG
#   OMOP database
DB_OMOP_DBMS=postgresql
DB_OMOP_PORT=5432
DB_OMOP_SERVER=postgres
DB_OMOP_DBNAME=OHDSI
DB_OMOP_SCHEMA=omopcdm
DB_OMOP_USER=feder8_admin # it must be feder8_admin as we are granting privilages to it
read -p "Password of your feder8_admin user in OHDSI DB: " DB_OMOP_PASSWORD
DB_OMOP_PASSWORD=${DB_OMOP_PASSWORD:-\"admin\"}
#   OPAL database
DB_SRC_DBMS=postgresql
DB_SRC_PORT=5432
DB_SRC_SERVER=ecrf-postgres
DB_SRC_DBNAME=postgres
DB_SRC_SCHEMA=opal
DB_SRC_USER=postgres #to define by the user 
read -p "Password of your postgres user in POSTGRES (ECRF) DB: " DB_SRC_PASSWORD
DB_SRC_PASSWORD=${DB_SRC_PASSWORD:-\"admin\"}


docker pull $REGISTRY/$REPOSITORY/$IMAGE:$TAG
docker run --rm -it --name det_etl --network feder8-net -e VERBOSITY_LEVEL=$VERBOSITY_LEVEL -e ETL_VERSION=$ETL_VERSION -e SOURCE_RELEASE_DATE=$SOURCE_RELEASE_DATE -e DB_OMOP_DBMS=$DB_OMOP_DBMS -e DB_OMOP_PORT=$DB_OMOP_PORT -e DB_OMOP_SERVER=$DB_OMOP_SERVER -e DB_OMOP_DBNAME=$DB_OMOP_DBNAME -e DB_OMOP_SCHEMA=$DB_OMOP_SCHEMA -e DB_OMOP_USER=$DB_OMOP_USER -e DB_OMOP_PASSWORD=$DB_OMOP_PASSWORD -e DB_SRC_DBMS=$DB_SRC_DBMS -e DB_SRC_PORT=$DB_SRC_PORT -e DB_SRC_SERVER=$DB_SRC_SERVER -e DB_SRC_DBNAME=$DB_SRC_DBNAME -e DB_SRC_SCHEMA=$DB_SRC_SCHEMA -e DB_SRC_USER=$DB_SRC_USER -e DB_SRC_PASSWORD=$DB_SRC_PASSWORD $REGISTRY/$REPOSITORY/$IMAGE:$TAG      

