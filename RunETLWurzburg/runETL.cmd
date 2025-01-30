@echo off

SET REGISTRY=harbor.honeur.org
SET REPOSITORY=library
SET IMAGE=etl-runner
SET VERSION=1.1.3
SET TAG=%VERSION%
SET DATA_FOLDER_HOST=%CD%\data
SET DATA_FOLDER=/script/etl/data
SET QA_FOLDER_HOST=%CD%\qa
SET QA_FOLDER_ETL=/script/etl/wurzburg/reports
SET LOG_FOLDER_HOST=%CD%\log
SET LOG_FOLDER_ETL=/script/etl/wurzburg/log

echo "Pull ETL runner Docker image"
docker pull %REGISTRY%/%REPOSITORY%/%IMAGE%:%TAG%

echo "Download questions for ETL"
curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/RunETLWurzburg/questions.json --output questions.json

echo "Create database schema 'wurzburg_final'"
docker exec -it postgres psql -U postgres -d OHDSI -c "CREATE SCHEMA IF NOT EXISTS wurzburg_final AUTHORIZATION ohdsi_admin;GRANT USAGE ON SCHEMA wurzburg_final TO ohdsi_app;GRANT SELECT ON ALL TABLES IN SCHEMA wurzburg_final TO ohdsi_app;GRANT USAGE ON SCHEMA wurzburg_final TO ohdsi_admin;GRANT ALL ON ALL TABLES IN SCHEMA wurzburg_final TO ohdsi_admin;"

echo "Run ETL"
docker run -it --rm --name etl-runner --env THERAPEUTIC_AREA=honeur --env REGISTRY=%REGISTRY% --env ETL_IMAGE_NAME=etl-wurzburg/etl --env ETL_IMAGE_TAG=latest --env DATA_FOLDER_HOST=%DATA_FOLDER_HOST% --env DATA_FOLDER=%DATA_FOLDER% --env QA_FOLDER_HOST=%QA_FOLDER_HOST% --env QA_FOLDER_ETL=%QA_FOLDER_ETL% --env LOG_FOLDER_HOST=%LOG_FOLDER_HOST% --env LOG_FOLDER=%LOG_FOLDER_ETL% --env RUN_DQD=false --env CDM_VERSION=5.4 -v /var/run/docker.sock:/var/run/docker.sock -v %CD%\questions.json:/script/questions.json --network feder8-net %REGISTRY%/%REPOSITORY%/%IMAGE%:%TAG%
echo "ETL run finished"

echo "Set correct permissions on new database schema's"
docker exec -it postgres psql -U postgres -d OHDSI -c "REASSIGN OWNED BY feder8_admin TO ohdsi_admin;REASSIGN OWNED BY ohdsi_app_user TO ohdsi_app;grant usage on schema wurzburg_final to ohdsi_app;GRANT SELECT ON ALL TABLES IN SCHEMA wurzburg_final TO ohdsi_app;"
docker exec -it postgres psql -U postgres -d OHDSI -c "GRANT USAGE ON SCHEMA wurzburg_cdm TO ohdsi_app;GRANT SELECT ON ALL TABLES IN SCHEMA wurzburg_cdm TO ohdsi_app;GRANT USAGE ON SCHEMA wurzburg_src TO ohdsi_app;GRANT SELECT ON ALL TABLES IN SCHEMA wurzburg_src TO ohdsi_app;"

