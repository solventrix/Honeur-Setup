#!/usr/bin/env bash
set -ex

docker exec -it postgres psql -U postgres -d OHDSI -c "ALTER SCHEMA omopcdm_53 RENAME TO omopcdm;"
docker exec -it postgres psql -U postgres -d OHDSI -c "ALTER SCHEMA results_53 RENAME TO results;"