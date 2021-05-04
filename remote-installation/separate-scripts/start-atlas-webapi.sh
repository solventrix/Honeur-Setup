#!/usr/bin/env bash
set -e

cr=$(echo $'\n.')
cr=${cr%.}

VERSION=2.0.1
TAG=2.7.1-$VERSION
CURRENT_DIRECTORY=$(pwd)

read -p 'Enter the Therapeutic Area of choice. Enter honeur/phederation/esfurn/athena [honeur]: ' FEDER8_THERAPEUTIC_AREA
while [[ "$FEDER8_THERAPEUTIC_AREA" != "honeur" && "$FEDER8_THERAPEUTIC_AREA" != "phederation" && "$FEDER8_THERAPEUTIC_AREA" != "esfurn" && "$FEDER8_THERAPEUTIC_AREA" != "athena" && "$FEDER8_THERAPEUTIC_AREA" != "" ]]; do
    echo "Enter \"honeur\", \"phederation\", \"esfurn\", \"athena\" or empty for default \"honeur\" value"
    read -p "Enter the Therapeutic Area of choice. Enter honeur/phederation/esfurn/athena [honeur]: " FEDER8_THERAPEUTIC_AREA
done
FEDER8_THERAPEUTIC_AREA=${FEDER8_THERAPEUTIC_AREA:-honeur}

if [ "$FEDER8_THERAPEUTIC_AREA" = "honeur" ]; then
    FEDER8_THERAPEUTIC_AREA_DOMAIN=honeur.org
    FEDER8_THERAPEUTIC_AREA_URL=harbor.$FEDER8_THERAPEUTIC_AREA_DOMAIN
elif [ "$FEDER8_THERAPEUTIC_AREA" = "phederation" ]; then
    FEDER8_THERAPEUTIC_AREA_DOMAIN=phederation.org
    FEDER8_THERAPEUTIC_AREA_URL=harbor.$FEDER8_THERAPEUTIC_AREA_DOMAIN
elif [ "$FEDER8_THERAPEUTIC_AREA" = "esfurn" ]; then
    FEDER8_THERAPEUTIC_AREA_DOMAIN=esfurn.org
    FEDER8_THERAPEUTIC_AREA_URL=harbor.$FEDER8_THERAPEUTIC_AREA_DOMAIN
elif [ "$FEDER8_THERAPEUTIC_AREA" = "athena" ]; then
    FEDER8_THERAPEUTIC_AREA_DOMAIN=athenafederation.org
    FEDER8_THERAPEUTIC_AREA_URL=harbor.$FEDER8_THERAPEUTIC_AREA_DOMAIN
fi

read -p "Enter email address used to login to https://portal.${FEDER8_THERAPEUTIC_AREA_DOMAIN}: " FEDER8_EMAIL_ADDRESS
while [[ "$FEDER8_EMAIL_ADDRESS" == "" ]]; do
    echo "Email address can not be empty"
    read -p "Enter email address used to login to https://portal.$FEDER8_THERAPEUTIC_AREA_DOMAIN: " FEDER8_EMAIL_ADDRESS
done
read -p "Surf to https://$FEDER8_THERAPEUTIC_AREA_URL and login using the button \"LOGIN VIA OIDC PROVIDER\". Then click your account name on the top right corner of the screen and click \"User Profile\". Copy the CLI secret by clicking the copy symbol next to the text field.${cr}Enter the CLI Secret: " FEDER8_CLI_SECRET
while [[ "$FEDER8_CLI_SECRET" == "" ]]; do
    echo "CLI Secret can not be empty"
    read -p "Enter the CLI Secret: " FEDER8_CLI_SECRET
done

read -p 'Enter the FQDN(Fully Qualified Domain Name eg. www.example.com) or public IP address(eg. 125.24.44.18) of the host machine. Use localhost to for testing [localhost]: ' FEDER8_HOST_MACHINE
FEDER8_HOST_MACHINE=${FEDER8_HOST_MACHINE:-localhost}
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
elif [ "$FEDER8_SECURITY_METHOD" = "jdbc" ]; then
    FEDER8_SECURITY_LDAP_URL=ldap://localhost:389
    FEDER8_SECURITY_LDAP_SYSTEM_USERNAME=username
    FEDER8_SECURITY_LDAP_SYSTEM_PASSWORD=password
    FEDER8_SECURITY_LDAP_BASE_DN=dc=example,dc=org
    FEDER8_SECURITY_LDAP_DN=cn={0},dc=example,dc=org
fi

touch atlas-webapi.env

echo "OHDSI_DATASOURCE_URL=jdbc:postgresql://postgres:5432/OHDSI" > atlas-webapi.env
echo "WEBAPI_URL=/webapi/" >> atlas-webapi.env
echo "JAVA_OPTS=-Xms512m -Xmx512m" >> atlas-webapi.env
echo "STORAGE_SERVER_BASE_URL=https://storage.$FEDER8_THERAPEUTIC_AREA_DOMAIN" >> atlas-webapi.env
if [ ! "$FEDER8_SECURITY_METHOD" = "none" ]; then
    echo "USER_AUTHENTICATION_ENABLED=true" >> atlas-webapi.env
    echo "LDAP_URL=$FEDER8_SECURITY_LDAP_URL" >> atlas-webapi.env
    echo "LDAP_SYSTEM_USERNAME=$FEDER8_SECURITY_LDAP_SYSTEM_USERNAME" >> atlas-webapi.env
    echo "LDAP_SYSTEM_PASSWORD=$FEDER8_SECURITY_LDAP_SYSTEM_PASSWORD" >> atlas-webapi.env
    echo "LDAP_BASE_DN=$FEDER8_SECURITY_LDAP_BASE_DN" >> atlas-webapi.env
    echo "LDAP_DN=$FEDER8_SECURITY_LDAP_DN" >> atlas-webapi.env
else
    echo "USER_AUTHENTICATION_ENABLED=false" >> atlas-webapi.env
fi

echo "Stop and remove webapi container if exists"
docker stop webapi > /dev/null 2>&1 || true
docker rm webapi > /dev/null 2>&1 || true

if [ ! "$FEDER8_SECURITY_METHOD" = "none" ]; then
    TAG=$TAG-secure
else
    TAG=$TAG-standard
fi

echo "Create $FEDER8_THERAPEUTIC_AREA-net network if it does not exists"
docker network create --driver bridge $FEDER8_THERAPEUTIC_AREA-net > /dev/null 2>&1 || true

echo "Pull $FEDER8_THERAPEUTIC_AREA/webapi-atlas:$TAG from https://$FEDER8_THERAPEUTIC_AREA_URL. This could take a while if not present on machine"
echo "$FEDER8_CLI_SECRET" | docker login https://$FEDER8_THERAPEUTIC_AREA_URL --username $FEDER8_EMAIL_ADDRESS --password-stdin
docker pull $FEDER8_THERAPEUTIC_AREA_URL/$FEDER8_THERAPEUTIC_AREA/webapi-atlas:$TAG

echo "Run $FEDER8_THERAPEUTIC_AREA/webapi-atlas:$TAG container. This could take a while..."
docker run \
--name "webapi" \
--restart on-failure:5 \
--security-opt no-new-privileges \
--env-file atlas-webapi.env \
-v "shared:/var/lib/shared:ro" \
-m "2g" \
--cpus "2" \
--pids-limit 150 \
--cpu-shares 1024 \
--ulimit nofile=1024:1024 \
-d \
$FEDER8_THERAPEUTIC_AREA_URL/$FEDER8_THERAPEUTIC_AREA/webapi-atlas:$TAG > /dev/null 2>&1

echo "Connect webapi to $FEDER8_THERAPEUTIC_AREA-net network"
docker network connect $FEDER8_THERAPEUTIC_AREA-net webapi > /dev/null 2>&1

echo "Clean up helper files"
rm -rf atlas-webapi.env

echo "Done"