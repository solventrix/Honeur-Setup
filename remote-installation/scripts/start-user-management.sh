#!/usr/bin/env bash
set -e

TAG="2.0.0"

read -p "usermgmt admin username [admin]: " HONEUR_USERMGMT_ADMIN_USERNAME
HONEUR_USERMGMT_ADMIN_USERNAME=${HONEUR_USERMGMT_ADMIN_USERNAME:-admin}
read -p "usermgmt admin password [admin]: " HONEUR_USERMGMT_ADMIN_PASSWORD
HONEUR_USERMGMT_ADMIN_PASSWORD=${HONEUR_USERMGMT_ADMIN_PASSWORD:-admin}

echo "HONEUR_USERMGMT_USERNAME=$HONEUR_USERMGMT_ADMIN_USERNAME" > user-mgmt.env
echo "HONEUR_USERMGMT_PASSWORD=$HONEUR_USERMGMT_ADMIN_PASSWORD" >> user-mgmt.env
echo "DATASOURCE_DRIVER_CLASS_NAME=org.postgresql.Driver" >> user-mgmt.env
echo "DATASOURCE_URL=jdbc:postgresql://postgres:5432/OHDSI?currentSchema=webapi" >> user-mgmt.env
echo "WEBAPI_ADMIN_USERNAME=ohdsi_admin_user" >> user-mgmt.env

docker stop user-mgmt > /dev/null 2>&1 || true
docker rm user-mgmt > /dev/null 2>&1 || true

docker network create --driver bridge honeur-net > /dev/null 2>&1 || true

docker run \
--name "user-mgmt" \
--restart always \
--security-opt no-new-privileges \
--env-file user-mgmt.env \
-v "shared:/var/lib/shared:ro" \
-d \
honeur/user-mgmt:$TAG

docker network connect honeur-net user-mgmt > /dev/null 2>&1 || true

rm -rf user-mgmt.env