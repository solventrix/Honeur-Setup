@echo off

SET REGISTRY=harbor.honeur.org
SET REPOSITORY=library
SET IMAGE=etl-runner
SET VERSION=1.1.2
SET TAG=%VERSION%

SET LOG_FOLDER_HOST=%CD%/log
SET QA_FOLDER_HOST=%CD%/qa

echo "Pull ETL runner image"
docker pull %REGISTRY%/%REPOSITORY%/%IMAGE%:%TAG%

curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/RunETLOMOP54Conversion/questions-omop54.json --output %CD%/questions-omop54.json

echo "Run ETL"
docker run -it --rm --name etl-runner-omop54 --env THERAPEUTIC_AREA=honeur --env REGISTRY=%REGISTRY% --env LOG_LEVEL=INFO --env VERBOSITY_LEVEL=INFO --env LOG_FOLDER_HOST=%LOG_FOLDER_HOST% --env LOG_FOLDER=/log --env ETL_IMAGE_NAME=etl-omop54/etl --env ETL_IMAGE_TAG=v1.2 --env QA_FOLDER_HOST=%QA_FOLDER_HOST% --env SRC_DB_53_SCHEMA=omopcdm --env RENAMED_SRC_DB_53_SCHEMA=omopcdm_53 --env TARGET_DB_54_SCHEMA=omopcdm --env SRC_VOCAB_DB_SCHEMA=omopcdm --env SRC_RESULTS_DB_53_SCHEMA=results --env RENAMED_SRC_RESULTS_DB_53_SCHEMA=results_53 --env TARGET_RESULTS_DB_54_SCHEMA=results --env SRC_PATIENT_CHECK_DB_SCHEMA=results --env RUN_DQD=true -v /var/run/docker.sock:/var/run/docker.sock  -v %CD%/questions-omop54.json:/script/questions.json --network feder8-net %REGISTRY%/%REPOSITORY%/%IMAGE%:%TAG%

echo "End of ETL run"
