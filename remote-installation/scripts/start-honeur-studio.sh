#!/usr/bin/env bash
set -e

VERSION=2.0.0
TAG=$VERSION
CURRENT_DIRECTORY=$(pwd)

read -p 'Enter the FQDN(Fully Qualified Domain Name eg. www.example.com) or public IP address(eg. 125.24.44.18) of the host machine. Use localhost to for testing [localhost]: ' HONEUR_HOST_MACHINE
HONEUR_HOST_MACHINE=${HONEUR_HOST_MACHINE:-localhost}

read -p "Enter the directory where HONEUR Studio will store its data [$CURRENT_DIRECTORY/honeurstudio]: " HONEUR_HONEUR_STUDIO_FOLDER
HONEUR_HONEUR_STUDIO_FOLDER=${HONEUR_HONEUR_STUDIO_FOLDER:-$CURRENT_DIRECTORY/honeurstudio}

read -p "Use jdbc users or LDAP or No for authentication? Enter jdbc/ldap/none. [none]: " HONEUR_SECURITY_METHOD
while [[ "$HONEUR_SECURITY_METHOD" != "none" && "$HONEUR_SECURITY_METHOD" != "ldap" && "$HONEUR_SECURITY_METHOD" != "jdbc" && "$HONEUR_SECURITY_METHOD" != "" ]]; do
    echo "enter \"none\", \"jdbc\", \"ldap\" or empty for default \"none\" value"
    read -p "Use JDBC users, LDAP or No authentication? Enter none/jdbc/ldap. [none]: " HONEUR_SECURITY_METHOD
done
HONEUR_SECURITY_METHOD=${HONEUR_SECURITY_METHOD:-none}

if [ "$HONEUR_SECURITY_METHOD" = "ldap" ]; then
    read -p "security.ldap.url [ldap://ldap.forumsys.com:389]: " HONEUR_SECURITY_LDAP_URL
    HONEUR_SECURITY_LDAP_URL=${HONEUR_SECURITY_LDAP_URL:-ldap://ldap.forumsys.com:389}
    read -p "security.ldap.system.username [cn=read-only-admin,dc=example,dc=com]: " HONEUR_SECURITY_LDAP_SYSTEM_USERNAME
    HONEUR_SECURITY_LDAP_SYSTEM_USERNAME=${HONEUR_SECURITY_LDAP_SYSTEM_USERNAME:-cn=read-only-admin,dc=example,dc=com}
    read -p "security.ldap.system.password [password]: " HONEUR_SECURITY_LDAP_SYSTEM_PASSWORD
    HONEUR_SECURITY_LDAP_SYSTEM_PASSWORD=${HONEUR_SECURITY_LDAP_SYSTEM_PASSWORD:-password}
    read -p "security.ldap.baseDn [dc=example,dc=com]: " HONEUR_SECURITY_LDAP_BASE_DN
    HONEUR_SECURITY_LDAP_BASE_DN=${HONEUR_SECURITY_LDAP_BASE_DN:-dc=example,dc=com}
    read -p "security.ldap.dn [uid={0},dc=example,dc=com]: " HONEUR_SECURITY_LDAP_DN
    HONEUR_SECURITY_LDAP_DN=${honeur_security_ldap_dn:-uid=\{0\},dc=example,dc=com}
fi

USERID=${UID:-1000}

echo "TAG=$TAG" > honeur-studio.env
echo "APPLICATION_LOGS_TO_STDOUT=false" >> honeur-studio.env
echo "SITE_NAME=honeurstudio" >> honeur-studio.env
echo "CONTENT_PATH=$HONEUR_HONEUR_STUDIO_FOLDER" >> honeur-studio.env
echo "USERID=$USERID" >> honeur-studio.env
echo "DOMAIN_NAME=$HONEUR_HOST_MACHINE" >> honeur-studio.env
echo "AUTHENTICATION_METHOD=$HONEUR_SECURITY_METHOD" >> honeur-studio.env
if [ "$HONEUR_SECURITY_METHOD" = "jdbc" ]; then
    #JDBC
    echo "DATASOURCE_DRIVER_CLASS_NAME=org.postgresql.Driver" >> honeur-studio.env
    echo "DATASOURCE_URL=jdbc:postgresql://postgres:5432/OHDSI?currentSchema=webapi" >> honeur-studio.env
    echo "WEBAPI_ADMIN_USERNAME=ohdsi_admin_user" >> honeur-studio.env
elif [ "$HONEUR_SECURITY_METHOD" = "ldap" ]; then
    #LDAP
    echo "HONEUR_STUDIO_LDAP_URL=$HONEUR_SECURITY_LDAP_URL/$HONEUR_SECURITY_LDAP_BASE_DN" >> honeur-studio.env
    echo "HONEUR_STUDIO_LDAP_DN=uid={0}" >> honeur-studio.env
    echo "HONEUR_STUDIO_LDAP_MANAGER_DN=$HONEUR_SECURITY_LDAP_SYSTEM_USERNAME" >> honeur-studio.env
    echo "HONEUR_STUDIO_LDAP_MANAGER_PASSWORD=$HONEUR_SECURITY_LDAP_SYSTEM_PASSWORD" >> honeur-studio.env
fi

echo "SITE_NAME=honeurstudio" > honeur-studio-chronicle.env
echo "USERID=$USERID" >> honeur-studio-chronicle.env
echo "USER=honeurstudio" >> honeur-studio-chronicle.env

docker stop $(docker ps --filter 'network=honeur-studio-net' -q -a) > /dev/null 2>&1 || true
docker rm $(docker ps --filter 'network=honeur-studio-net' -q -a) > /dev/null 2>&1 || true

docker network create --driver bridge honeur-net > /dev/null 2>&1 || true
docker network create --driver bridge honeur-studio-frontend-net > /dev/null 2>&1 || true
docker network create --driver bridge honeur-studio-net > /dev/null 2>&1 || true

docker pull honeur/honeur-studio:$TAG

docker run \
--name "honeur-studio-chronicle" \
-p "8085:3012" \
--restart always \
--env-file honeur-studio-chronicle.env \
--hostname "cronicle" \
-v "${HONEUR_HONEUR_STUDIO_FOLDER}:/home/honeurstudio/__HONEURStudio__:z" \
-v "r_libraries:/r-libs" \
-v "py_environment:/conda" \
-v "cronicle_data:/opt/cronicle" \
-v "pwsh_modules:/home/honeurstudio/.local/share/powershell/Modules" \
-d \
honeur/honeur-studio:$TAG cronicle

docker network connect honeur-studio-frontend-net honeur-studio-chronicle > /dev/null 2>&1 || true
docker network connect honeur-studio-net honeur-studio-chronicle > /dev/null 2>&1 || true
docker network connect honeur-net honeur-studio-chronicle > /dev/null 2>&1 || true

docker run \
--name "honeur-studio" \
-p "8084:8080" \
--restart always \
--env-file honeur-studio.env \
-v "shared:/var/lib/shared:ro" \
-v "/var/run/docker.sock:/var/run/docker.sock" \
-d \
honeur/honeur-studio:$TAG shinyproxy > /dev/null 2>&1

docker network connect honeur-net honeur-studio > /dev/null 2>&1 || true
docker network connect honeur-studio-frontend-net honeur-studio > /dev/null 2>&1 || true
docker network connect honeur-studio-net honeur-studio > /dev/null 2>&1 || true

rm -rf honeur-studio.env
rm -rf honeur-studio-chronicle.env
