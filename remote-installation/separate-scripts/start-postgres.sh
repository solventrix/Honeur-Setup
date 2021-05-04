#!/usr/bin/env bash
set -e

export LC_CTYPE=C

cr=$(echo $'\n.')
cr=${cr%.}

VERSION=2.0.1
TAG=9.6-omopcdm-5.3.1-webapi-2.7.1-$VERSION

FEDER8_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
FEDER8_ADMIN_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)

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

read -p "Enter email address used to login to https://portal.$FEDER8_THERAPEUTIC_AREA_DOMAIN: " FEDER8_EMAIL_ADDRESS
while [[ "$FEDER8_EMAIL_ADDRESS" == "" ]]; do
    echo "Email address can not be empty"
    read -p "Enter email address used to login to https://portal.$FEDER8_THERAPEUTIC_AREA_DOMAIN: " FEDER8_EMAIL_ADDRESS
done
read -p "Surf to https://$FEDER8_THERAPEUTIC_AREA_URL and login using the button \"LOGIN VIA OIDC PROVIDER\". Then click your account name on the top right corner of the screen and click \"User Profile\". Copy the CLI secret by clicking the copy symbol next to the text field.${cr}Enter the CLI Secret: " FEDER8_CLI_SECRET
while [[ "$FEDER8_CLI_SECRET" == "" ]]; do
    echo "CLI Secret can not be empty"
    read -p "Enter the CLI Secret: " FEDER8_CLI_SECRET
done

read -p "Enter password for $FEDER8_THERAPEUTIC_AREA database user [$FEDER8_PASSWORD]: " FEDER8_NEW_PASSWORD
FEDER8_NEW_PASSWORD=${FEDER8_NEW_PASSWORD:-$FEDER8_PASSWORD}
read -p "Enter password for ${FEDER8_THERAPEUTIC_AREA}_admin database user [$FEDER8_ADMIN_PASSWORD]: " FEDER8_NEW_ADMIN_PASSWORD
FEDER8_NEW_ADMIN_PASSWORD=${FEDER8_NEW_ADMIN_PASSWORD:-$FEDER8_ADMIN_PASSWORD}

echo "This script will install version 2.0.1 of the $FEDER8_THERAPEUTIC_AREA database. All $FEDER8_THERAPEUTIC_AREA docker containers will be restarted after running this script."

touch postgres.env

echo "HONEUR_USER_USERNAME=$FEDER8_THERAPEUTIC_AREA" > postgres.env
echo "HONEUR_USER_PW=$FEDER8_NEW_PASSWORD" >> postgres.env
echo "HONEUR_ADMIN_USER_USERNAME=${FEDER8_THERAPEUTIC_AREA}_admin" >> postgres.env
echo "HONEUR_ADMIN_USER_PW=$FEDER8_NEW_ADMIN_PASSWORD" >> postgres.env

echo "Stop and remove postgres container if exists"
docker stop postgres > /dev/null 2>&1 || true
docker rm postgres > /dev/null 2>&1 || true

echo "Removing existing helper volumes"
docker volume rm shared > /dev/null 2>&1 || true

echo "Create $FEDER8_THERAPEUTIC_AREA-net network if it does not exists"
docker network create --driver bridge $FEDER8_THERAPEUTIC_AREA-net > /dev/null 2>&1 || true

echo "Pull $FEDER8_THERAPEUTIC_AREA/postgres:$TAG from https://$FEDER8_THERAPEUTIC_AREA_URL. This could take a while if not present on machine..."
echo "$FEDER8_CLI_SECRET" | docker login https://$FEDER8_THERAPEUTIC_AREA_URL --username $FEDER8_EMAIL_ADDRESS --password-stdin
docker pull $FEDER8_THERAPEUTIC_AREA_URL/$FEDER8_THERAPEUTIC_AREA/postgres:$TAG

echo "Creating helper volumes"
docker volume create shared > /dev/null 2>&1 || true
docker volume create pgdata > /dev/null 2>&1 || true

echo "Run $FEDER8_THERAPEUTIC_AREA/postgres:$TAG container. This could take a while..."
docker run \
--name "postgres" \
--restart on-failure:5 \
--security-opt no-new-privileges \
--env-file postgres.env \
-p "5444:5432" \
-v "pgdata:/var/lib/postgresql/data" \
-v "shared:/var/lib/postgresql/envfileshared" \
-m "2g" \
--cpus "2" \
--pids-limit 100 \
--cpu-shares 1024 \
--ulimit nofile=1024:1024 \
-d \
$FEDER8_THERAPEUTIC_AREA_URL/$FEDER8_THERAPEUTIC_AREA/postgres:$TAG > /dev/null 2>&1

echo "Connect postgres to $FEDER8_THERAPEUTIC_AREA-net network"
docker network connect $FEDER8_THERAPEUTIC_AREA-net postgres > /dev/null 2>&1

echo "Clean up helper files"
rm -rf postgres.env

echo "Done"

echo "Restarting $FEDER8_THERAPEUTIC_AREA Components"
docker restart webapi > /dev/null 2>&1 || true
docker restart user-mgmt > /dev/null 2>&1 || true
docker restart zeppelin > /dev/null 2>&1 || true
docker restart $FEDER8_THERAPEUTIC_AREA-studio > /dev/null 2>&1 || true
docker restart $FEDER8_THERAPEUTIC_AREA-studio-chronicle > /dev/null 2>&1 || true