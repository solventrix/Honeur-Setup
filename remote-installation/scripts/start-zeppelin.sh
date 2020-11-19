#!/usr/bin/env bash
set -e

VERSION=2.0.0
TAG=0.8.2-$VERSION
CURRENT_DIRECTORY=$(pwd)

read -p "Enter the directory where the zeppelin logs will kept on the host machine [$CURRENT_DIRECTORY/zeppelin/logs]: " HONEUR_ZEPPELIN_LOGS
HONEUR_ZEPPELIN_LOGS=${HONEUR_ZEPPELIN_LOGS:-$CURRENT_DIRECTORY/zeppelin/logs}
read -p "Enter the directory where the zeppelin notebooks will kept on the host machine [$CURRENT_DIRECTORY/zeppelin/notebook]: " HONEUR_ZEPPELIN_NOTEBOOKS
HONEUR_ZEPPELIN_NOTEBOOKS=${HONEUR_ZEPPELIN_NOTEBOOKS:-$CURRENT_DIRECTORY/zeppelin/notebook}
read -p "Enter the directory where Zeppelin will save the prepared distributed analytics data [$CURRENT_DIRECTORY/distributed-analytics]: " HONEUR_ANALYTICS_SHARED_FOLDER
HONEUR_ANALYTICS_SHARED_FOLDER=${HONEUR_ANALYTICS_SHARED_FOLDER:-$CURRENT_DIRECTORY/distributed-analytics}

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

touch zeppelin.env

echo "ZEPPELIN_NOTEBOOK_DIR=/notebook" > zeppelin.env
echo "ZEPPELIN_LOG_DIR=/logs" >> zeppelin.env
if [ "$HONEUR_SECURITY_METHOD" = "jdbc" ]; then
    #JDBC
    echo "ZEPPELIN_SECURITY=$HONEUR_SECURITY_METHOD" >> zeppelin.env
    echo "LDAP_URL=ldap://localhost:389" >> zeppelin.env
    echo "LDAP_BASE_DN=dc=example,dc=org" >> zeppelin.env
    echo "LDAP_DN=cn={0},dc=example,dc=org" >> zeppelin.env
elif [ "$HONEUR_SECURITY_METHOD" = "ldap" ]; then
    #LDAP
    echo "ZEPPELIN_SECURITY=$HONEUR_SECURITY_METHOD" >> zeppelin.env
    echo "LDAP_URL=$HONEUR_SECURITY_LDAP_URL" >> zeppelin.env
    echo "LDAP_BASE_DN=$HONEUR_SECURITY_LDAP_BASE_DN" >> zeppelin.env
    echo "LDAP_DN=$HONEUR_SECURITY_LDAP_DN" >> zeppelin.env
fi

echo "Stop and remove zeppelin container if exists"
docker stop zeppelin > /dev/null 2>&1 || true
docker rm zeppelin > /dev/null 2>&1 || true

echo "Create honeur-net network if it does not exists"
docker network create --driver bridge honeur-net > /dev/null 2>&1 || true

echo "Pull honeur/zeppelin:$TAG from docker hub. This could take a while if not present on machine"
docker pull honeur/zeppelin:$TAG > /dev/null 2>&1

echo "Run honeur/zeppelin:$TAG container. This could take a while..."
docker run \
--name "zeppelin" \
--restart always \
--security-opt no-new-privileges \
--env-file zeppelin.env \
-v "shared:/var/lib/shared:ro" \
-v $HONEUR_ANALYTICS_SHARED_FOLDER:/usr/local/src/datafiles \
-v $HONEUR_ZEPPELIN_LOGS:/logs \
-v $HONEUR_ZEPPELIN_NOTEBOOKS:/notebook \
-d \
honeur/zeppelin:$TAG > /dev/null 2>&1

echo "Connect zeppelin to honeur-net network"
docker network connect honeur-net zeppelin > /dev/null 2>&1

echo "Clean up helper files"
rm -rf zeppelin.env

echo "Done"