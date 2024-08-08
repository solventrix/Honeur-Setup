#!/usr/bin/env bash
set +x
set +v

# Preprocess
REGISTRY_PREP=harbor.honeur.org
REPOSITORY_PREP=etl-det
IMAGE_PREP=det-oncocologne-preprocessing
TAG_PREP=v1.0
# ETL 
REGISTRY_ETL=harbor.honeur.org
REPOSITORY_ETL=etl-det
IMAGE_ETL=etl
TAG_ETL=v1.1.2
# Postprocess
REGISTRY_POST=harbor.honeur.org
REPOSITORY_POST=etl-det
IMAGE_POST=det-oncocologne-postprocessing
TAG_POST=v1.0

echo "###########################################################"
echo "########### Set privileges for user feder8_admin ###########"
echo "###########################################################"
docker exec -it postgres psql -U postgres -d OHDSI -c "ALTER USER feder8_admin WITH SUPERUSER;"

echo "###########################################################"
echo "################ Questions for the user ###################"
echo "###########################################################"
# ENV VARIABLES 
read -p "Source relesed date? [YYYY/MM/DD]: " SOURCE_RELEASE_DATE
SOURCE_RELEASE_DATE=${SOURCE_RELEASE_DATE:-\"2024/08/08\"}

read -p "Password of your feder8_admin user in OHDSI DB: " DB_OMOP_PASSWORD
DB_OMOP_PASSWORD=${DB_OMOP_PASSWORD:-\"admin\"}

read -p "Password of your postgres user in POSTGRES (ECRF) DB: " DB_SRC_PASSWORD
DB_SRC_PASSWORD=${DB_SRC_PASSWORD:-\"admin\"}

# FIXED ENV VARIABLES - OncoCologne
ETL_VERSION=$VERSION
VERBOSITY_LEVEL=DEBUG
#   OHDSI database
DB_OMOP_DBMS=postgresql
DB_OMOP_PORT=5432
DB_OMOP_SERVER=postgres
DB_OMOP_DBNAME=OHDSI
DB_OMOP_SCHEMA=omopcdm
DB_OMOP_USER=feder8_admin # it must be feder8_admin as we are granting privilages to it
#   SOURCE database
DB_SRC_DBMS=postgresql
DB_SRC_PORT=5432
DB_SRC_SERVER=ecrf-postgres
DB_SRC_DBNAME=opal
DB_SRC_SCHEMA=opal

echo "###########################################################"
echo "################ Running Preprocessing #####################"
echo "###########################################################"

docker pull $REGISTRY_PREP/$REPOSITORY_PREP/$IMAGE_PREP:$TAG_PREP
docker run --rm -it --name pre_det_etl --network feder8-net -e VERBOSITY_LEVEL=$VERBOSITY_LEVEL -e ETL_VERSION=$ETL_VERSION -e SOURCE_RELEASE_DATE=$SOURCE_RELEASE_DATE -e DB_OMOP_DBMS=$DB_OMOP_DBMS -e DB_OMOP_PORT=$DB_OMOP_PORT -e DB_OMOP_SERVER=$DB_OMOP_SERVER -e DB_OMOP_DBNAME=$DB_OMOP_DBNAME -e DB_OMOP_SCHEMA=$DB_OMOP_SCHEMA -e DB_OMOP_USER=$DB_OMOP_USER -e DB_OMOP_PASSWORD=$DB_OMOP_PASSWORD -e DB_SRC_DBMS=$DB_SRC_DBMS -e DB_SRC_PORT=$DB_SRC_PORT -e DB_SRC_SERVER=$DB_SRC_SERVER -e DB_SRC_DBNAME=$DB_SRC_DBNAME -e DB_SRC_SCHEMA=$DB_SRC_SCHEMA -e DB_SRC_USER=$DB_SRC_USER -e DB_SRC_PASSWORD=$DB_SRC_PASSWORD $REGISTRY_PREP/$REPOSITORY_PREP/$IMAGE_PREP:$TAG_PREP

echo "###########################################################"
echo "##################### Running ETL ##########################"
echo "###########################################################"

DB_SRC_DBNAME=OHDSI # data already in OHDSI database
echo "Run det-etl"
docker pull $REGISTRY_ETL/$REPOSITORY_ETL/$IMAGE_ETL:$TAG_ETL
docker run --rm -it --name det_etl --network feder8-net -e VERBOSITY_LEVEL=$VERBOSITY_LEVEL -e ETL_VERSION=$ETL_VERSION -e SOURCE_RELEASE_DATE=$SOURCE_RELEASE_DATE -e DB_OMOP_DBMS=$DB_OMOP_DBMS -e DB_OMOP_PORT=$DB_OMOP_PORT -e DB_OMOP_SERVER=$DB_OMOP_SERVER -e DB_OMOP_DBNAME=$DB_OMOP_DBNAME -e DB_OMOP_SCHEMA=$DB_OMOP_SCHEMA -e DB_OMOP_USER=$DB_OMOP_USER -e DB_OMOP_PASSWORD=$DB_OMOP_PASSWORD -e DB_SRC_DBMS=$DB_SRC_DBMS -e DB_SRC_PORT=$DB_SRC_PORT -e DB_SRC_SERVER=$DB_SRC_SERVER -e DB_SRC_DBNAME=$DB_SRC_DBNAME -e DB_SRC_SCHEMA=$DB_SRC_SCHEMA -e DB_SRC_USER=$DB_SRC_USER -e DB_SRC_PASSWORD=$DB_SRC_PASSWORD $REGISTRY_ETL/$REPOSITORY_ETL/$IMAGE_ETL:$TAG_ETL

echo "###########################################################"
echo "################ Running Postprocessing ####################"
echo "###########################################################"

DB_DBMS=$DB_OMOP_DBMS
DB_PORT=$DB_OMOP_PORT
DB_SERVER=$DB_OMOP_SERVER
DB_DBNAME=$DB_OMOP_DBNAME
DB_SCHEMA=$DB_OMOP_SCHEMA
DB_USER=$DB_OMOP_USER
DB_PASSWORD=$DB_OMOP_PASSWORD
PATIENT_CHECK_PREPROCESSING_SCHEMA=$DB_SRC_SCHEMA
echo "Run det-oncocologne-postprocessing"
docker pull $REGISTRY_POST/$REPOSITORY_POST/$IMAGE_POST:$TAG_POST
docker run --rm -it --name post_det_etl --network feder8-net -e VERBOSITY_LEVEL=$VERBOSITY_LEVEL -e ETL_VERSION=$ETL_VERSION -e SOURCE_RELEASE_DATE=$SOURCE_RELEASE_DATE -e DB_DBMS=$DB_DBMS -e DB_PORT=$DB_PORT -e DB_SERVER=$DB_SERVER -e DB_DBNAME=$DB_DBNAME -e DB_SCHEMA=$DB_SCHEMA -e DB_USER=$DB_USER -e DB_PASSWORD=$DB_PASSWORD -e PATIENT_CHECK_PREPROCESSING_SCHEMA=$PATIENT_CHECK_PREPROCESSING_SCHEMA $REGISTRY_POST/$REPOSITORY_POST/$IMAGE_POST:$TAG_POST
