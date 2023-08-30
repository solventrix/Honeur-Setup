@echo off

SET REGISTRY=harbor.honeur.org
SET REPOSITORY=library
SET IMAGE=etl-runner
SET TAG=1.1.2

SET LOG_FOLDER_HOST=%CD%/log
SET QA_FOLDER_HOST=%CD%/qa

echo "Pull ETL runner image"
docker pull %REGISTRY%/%REPOSITORY%/%IMAGE%:%TAG%

echo "Download configuration for ETL"
curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/RunETLDET/questions-det.json --output %CD%/questions-det.json

echo "Run ETL"
docker run -it --rm --name det-etl-runner --env THERAPEUTIC_AREA=honeur --env REGISTRY=%REGISTRY% --env LOG_FOLDER_HOST=%LOG_FOLDER_HOST% --env LOG_FOLDER=/log --env ETL_IMAGE_NAME=etl-det/etl --env ETL_IMAGE_TAG=v1.1.1 --env QA_FOLDER_HOST=%QA_FOLDER_HOST% --env DB_OMOP_DBMS=postgresql --env DB_OMOP_PORT=5432 --env DB_OMOP_SERVER=postgres --env DB_OMOP_DBNAME=OHDSI --env DB_OMOP_SCHEMA=omopcdm54 --env DB_SRC_DBMS=postgresql --env DB_SRC_PORT=5432 --env DB_SRC_SERVER=ecrf-postgres --env DB_SRC_DBNAME=postgres --env DB_SRC_SCHEMA=opal --env RUN_DQD=true -v /var/run/docker.sock:/var/run/docker.sock -v %CD%/questions-det.json:/script/questions.json --network feder8-net %REGISTRY%/%REPOSITORY%/%IMAGE%:%TAG%
echo "End of ETL run"
