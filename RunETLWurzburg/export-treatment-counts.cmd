@echo off

SET REGISTRY=harbor.honeur.org
SET REPOSITORY=etl-wurzburg
SET IMAGE=treatment-counts-export
SET TAG=1.0.0

SET DATA_FOLDER_HOST="%CD%/data"
SET /p "DATA_FOLDER_HOST=Source data folder [%DATA_FOLDER_HOST%]: "

SET OUTPUT_FOLDER_HOST=%CD%/output

docker pull %REGISTRY%/%REPOSITORY%/%IMAGE%:%TAG%
docker run --rm -it -v %DATA_FOLDER_HOST%:/script/data -v %OUTPUT_FOLDER_HOST%:/script/output %REGISTRY%/%REPOSITORY%/%IMAGE%:%TAG%
