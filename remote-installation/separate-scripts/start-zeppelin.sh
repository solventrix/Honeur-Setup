#!/usr/bin/env bash
set -e

VERSION=2.0.0
TAG=0.8.2-$VERSION
CURRENT_DIRECTORY=$(pwd)

read -p 'Enter the Therapeutic Area of choice. Enter honeur/phederation/esfurn/athena [honeur]: ' FEDER8_THERAPEUTIC_AREA
while [[ "$FEDER8_THERAPEUTIC_AREA" != "honeur" && "$FEDER8_THERAPEUTIC_AREA" != "phederation" && "$FEDER8_THERAPEUTIC_AREA" != "esfurn" && "$FEDER8_THERAPEUTIC_AREA" != "athena" && "$FEDER8_THERAPEUTIC_AREA" != "" ]]; do
    echo "Enter \"honeur\", \"phederation\", \"esfurn\", \"athena\" or empty for default \"honeur\" value"
    read -p "Enter the Therapeutic Area of choice. Enter honeur/phederation/esfurn/athena [honeur]: " FEDER8_THERAPEUTIC_AREA
done
FEDER8_THERAPEUTIC_AREA=${FEDER8_THERAPEUTIC_AREA:-honeur}

if [ "$FEDER8_THERAPEUTIC_AREA" = "honeur" ]; then
    FEDER8_THERAPEUTIC_AREA_DOMAIN=honeur.org
    FEDER8_THERAPEUTIC_AREA_URL=harbor-uat.$FEDER8_THERAPEUTIC_AREA_DOMAIN
elif [ "$FEDER8_THERAPEUTIC_AREA" = "phederation" ]; then
    FEDER8_THERAPEUTIC_AREA_DOMAIN=phederation.org
    FEDER8_THERAPEUTIC_AREA_URL=harbor-uat.$FEDER8_THERAPEUTIC_AREA_DOMAIN
elif [ "$FEDER8_THERAPEUTIC_AREA" = "esfurn" ]; then
    FEDER8_THERAPEUTIC_AREA_DOMAIN=esfurn.org
    FEDER8_THERAPEUTIC_AREA_URL=harbor-uat.$FEDER8_THERAPEUTIC_AREA_DOMAIN
elif [ "$FEDER8_THERAPEUTIC_AREA" = "athena" ]; then
    FEDER8_THERAPEUTIC_AREA_DOMAIN=athenafederation.org
    FEDER8_THERAPEUTIC_AREA_URL=harbor-uat.$FEDER8_THERAPEUTIC_AREA_DOMAIN
fi

read -p "Enter email address used to login to https://portal-uat.$FEDER8_THERAPEUTIC_AREA_DOMAIN: " FEDER8_EMAIL_ADDRESS
while [[ "$FEDER8_EMAIL_ADDRESS" == "" ]]; do
    echo "Email address can not be empty"
    read -p "Enter email address used to login to https://portal-uat.$FEDER8_THERAPEUTIC_AREA_DOMAIN: " FEDER8_EMAIL_ADDRESS
done
echo "Surf to https://$FEDER8_THERAPEUTIC_AREA_URL and login using the button \"LOGIN VIA OIDC PROVIDER\". Then click your account name on the top right corner of the screen and click \"User Profile\". Copy the CLI secret by clicking the copy symbol next to the text field."
read -p 'Enter the CLI Secret: ' FEDER8_CLI_SECRET
while [[ "$FEDER8_CLI_SECRET" == "" ]]; do
    echo "CLI Secret can not be empty"
    read -p "Enter the CLI Secret: " FEDER8_CLI_SECRET
done

read -p "Enter the directory where the zeppelin logs will kept on the host machine [$CURRENT_DIRECTORY/zeppelin/logs]: " FEDER8_ZEPPELIN_LOGS
FEDER8_ZEPPELIN_LOGS=${FEDER8_ZEPPELIN_LOGS:-$CURRENT_DIRECTORY/zeppelin/logs}
read -p "Enter the directory where the zeppelin notebooks will kept on the host machine [$CURRENT_DIRECTORY/zeppelin/notebook]: " FEDER8_ZEPPELIN_NOTEBOOKS
FEDER8_ZEPPELIN_NOTEBOOKS=${FEDER8_ZEPPELIN_NOTEBOOKS:-$CURRENT_DIRECTORY/zeppelin/notebook}
read -p "Enter the directory where Zeppelin will save the prepared distributed analytics data [$CURRENT_DIRECTORY/distributed-analytics]: " FEDER8_ANALYTICS_SHARED_FOLDER
FEDER8_ANALYTICS_SHARED_FOLDER=${FEDER8_ANALYTICS_SHARED_FOLDER:-$CURRENT_DIRECTORY/distributed-analytics}

read -p "Use jdbc users or LDAP or No for authentication? Enter jdbc/ldap/none. [none]: " FEDER8_SECURITY_METHOD
while [[ "$FEDER8_SECURITY_METHOD" != "none" && "$FEDER8_SECURITY_METHOD" != "ldap" && "$FEDER8_SECURITY_METHOD" != "jdbc" && "$FEDER8_SECURITY_METHOD" != "" ]]; do
    echo "enter \"none\", \"jdbc\", \"ldap\" or empty for default \"none\" value"
    read -p "Use JDBC users, LDAP or No authentication? Enter none/jdbc/ldap. [none]: " FEDER8_SECURITY_METHOD
done
FEDER8_SECURITY_METHOD=${FEDER8_SECURITY_METHOD:-none}

if [ "$FEDER8_SECURITY_METHOD" = "ldap" ]; then
    read -p "security.ldap.url [ldap://ldap.forumsys.com:389]: " FEDER8_SECURITY_LDAP_URL
    FEDER8_SECURITY_LDAP_URL=${FEDER8_SECURITY_LDAP_URL:-ldap://ldap.forumsys.com:389}
    read -p "security.ldap.system.username [cn=read-only-admin,dc=example,dc=com]: " FEDER8_SECURITY_LDAP_SYSTEM_USERNAME
    FEDER8_SECURITY_LDAP_SYSTEM_USERNAME=${FEDER8_SECURITY_LDAP_SYSTEM_USERNAME:-cn=read-only-admin,dc=example,dc=com}
    read -p "security.ldap.system.password [password]: " FEDER8_SECURITY_LDAP_SYSTEM_PASSWORD
    FEDER8_SECURITY_LDAP_SYSTEM_PASSWORD=${FEDER8_SECURITY_LDAP_SYSTEM_PASSWORD:-password}
    read -p "security.ldap.baseDn [dc=example,dc=com]: " FEDER8_SECURITY_LDAP_BASE_DN
    FEDER8_SECURITY_LDAP_BASE_DN=${FEDER8_SECURITY_LDAP_BASE_DN:-dc=example,dc=com}
    read -p "security.ldap.dn [uid={0},dc=example,dc=com]: " FEDER8_SECURITY_LDAP_DN
    FEDER8_SECURITY_LDAP_DN=${FEDER8_SECURITY_LDAP_DN:-uid=\{0\},dc=example,dc=com}
fi

touch zeppelin.env

echo "ZEPPELIN_NOTEBOOK_DIR=/notebook" > zeppelin.env
echo "ZEPPELIN_LOG_DIR=/logs" >> zeppelin.env
if [ "$FEDER8_SECURITY_METHOD" = "jdbc" ]; then
    #JDBC
    echo "ZEPPELIN_SECURITY=$FEDER8_SECURITY_METHOD" >> zeppelin.env
    echo "LDAP_URL=ldap://localhost:389" >> zeppelin.env
    echo "LDAP_BASE_DN=dc=example,dc=org" >> zeppelin.env
    echo "LDAP_DN=cn={0},dc=example,dc=org" >> zeppelin.env
elif [ "$FEDER8_SECURITY_METHOD" = "ldap" ]; then
    #LDAP
    echo "ZEPPELIN_SECURITY=$FEDER8_SECURITY_METHOD" >> zeppelin.env
    echo "LDAP_URL=$FEDER8_SECURITY_LDAP_URL" >> zeppelin.env
    echo "LDAP_BASE_DN=$FEDER8_SECURITY_LDAP_BASE_DN" >> zeppelin.env
    echo "LDAP_DN=$FEDER8_SECURITY_LDAP_DN" >> zeppelin.env
fi

echo "Stop and remove zeppelin container if exists"
docker stop zeppelin > /dev/null 2>&1 || true
docker rm zeppelin > /dev/null 2>&1 || true

echo "Create $FEDER8_THERAPEUTIC_AREA-net network if it does not exists"
docker network create --driver bridge $FEDER8_THERAPEUTIC_AREA-net > /dev/null 2>&1 || true

echo "Pull $FEDER8_THERAPEUTIC_AREA/zeppelin:$TAG from https://$FEDER8_THERAPEUTIC_AREA_URL. This could take a while if not present on machine"
echo "$FEDER8_CLI_SECRET" | docker login https://$FEDER8_THERAPEUTIC_AREA_URL --username $FEDER8_EMAIL_ADDRESS --password-stdin
docker pull $FEDER8_THERAPEUTIC_AREA_URL/$FEDER8_THERAPEUTIC_AREA/zeppelin:$TAG

echo "Run $FEDER8_THERAPEUTIC_AREA/zeppelin:$TAG container. This could take a while..."
docker run \
--name "zeppelin" \
--restart on-failure:5 \
--security-opt no-new-privileges \
--env-file zeppelin.env \
-v "shared:/var/lib/shared:ro" \
-v $FEDER8_ANALYTICS_SHARED_FOLDER:/usr/local/src/datafiles \
-v $FEDER8_ZEPPELIN_LOGS:/logs \
-v $FEDER8_ZEPPELIN_NOTEBOOKS:/notebook \
-m "4g" \
--cpus "2" \
--pids-limit 200 \
--cpu-shares 1024 \
--ulimit nofile=1024:1024 \
-d \
$FEDER8_THERAPEUTIC_AREA_URL/$FEDER8_THERAPEUTIC_AREA/zeppelin:$TAG > /dev/null 2>&1

echo "Connect zeppelin to $FEDER8_THERAPEUTIC_AREA-net network"
docker network connect $FEDER8_THERAPEUTIC_AREA-net zeppelin > /dev/null 2>&1

echo "Clean up helper files"
rm -rf zeppelin.env

echo "Done"