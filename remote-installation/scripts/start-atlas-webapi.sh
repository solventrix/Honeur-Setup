#!/usr/bin/env bash
set -e

VERSION=2.0.0
TAG=2.7.1-$VERSION
CURRENT_DIRECTORY=$(pwd)


read -p 'Enter the FQDN(Fully Qualified Domain Name eg. www.example.com) or public IP address(eg. 125.24.44.18) of the host machine. Use localhost to for testing [localhost]: ' HONEUR_HOST_MACHINE
HONEUR_HOST_MACHINE=${HONEUR_HOST_MACHINE:-localhost}
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

echo "OHDSI_DATASOURCE_URL=jdbc:postgresql://postgres:5432/OHDSI" > atlas-webapi.env
echo "WEBAPI_URL=/webapi/" >> atlas-webapi.env
echo "JAVA_OPTS=-Xms512m -Xmx512m" >> atlas-webapi.env
if [ ! "$HONEUR_SECURITY_METHOD" = "none" ]; then
    echo "USER_AUTHENTICATION_ENABLED=true" >> atlas-webapi.env
    echo "LDAP_URL=$HONEUR_SECURITY_LDAP_URL" >> atlas-webapi.env
    echo "LDAP_SYSTEM_USERNAME=$HONEUR_SECURITY_LDAP_SYSTEM_USERNAME" >> atlas-webapi.env
    echo "LDAP_SYSTEM_PASSWORD=$HONEUR_SECURITY_LDAP_SYSTEM_PASSWORD" >> atlas-webapi.env
    echo "LDAP_BASE_DN=$HONEUR_SECURITY_LDAP_BASE_DN" >> atlas-webapi.env
    echo "LDAP_DN=$HONEUR_SECURITY_LDAP_DN" >> atlas-webapi.env
else
    echo "USER_AUTHENTICATION_ENABLED=false" >> atlas-webapi.env
fi

docker stop webapi > /dev/null 2>&1 || true
docker rm webapi > /dev/null 2>&1 || true

docker network create --driver bridge honeur-net > /dev/null 2>&1 || true

if [ ! "$HONEUR_SECURITY_METHOD" = "none" ]; then
    TAG=$TAG-secure
else
    TAG=$TAG-standard
fi

docker run \
--name "webapi" \
--restart always \
--security-opt no-new-privileges \
--env-file atlas-webapi.env \
-v "shared:/var/lib/shared:ro" \
-d \
honeur/webapi-atlas:$TAG > /dev/null

docker network connect honeur-net webapi > /dev/null 2>&1 || true

rm -rf atlas-webapi.env
