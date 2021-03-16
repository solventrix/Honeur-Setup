#!/usr/bin/env bash
set -e

export LC_CTYPE=C

VERSION=2.0.1
TAG=9.6-omopcdm-5.3.1-webapi-2.7.1-$VERSION

HONEUR_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
HONEUR_ADMIN_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)

read -p 'Enter the Therapeutic Area of choice. Enter honeur/phederation/esfurn/athena [honeur]: ' HONEUR_THERAPEUTIC_AREA
while [[ "$HONEUR_THERAPEUTIC_AREA" != "honeur" && "$HONEUR_THERAPEUTIC_AREA" != "phederation" && "$HONEUR_THERAPEUTIC_AREA" != "esfurn" && "$HONEUR_THERAPEUTIC_AREA" != "athena" && "$HONEUR_THERAPEUTIC_AREA" != "" ]]; do
    echo "Enter \"honeur\", \"phederation\", \"esfurn\", \"athena\" or empty for default \"honeur\" value"
    read -p "Enter the Therapeutic Area of choice. Enter honeur/phederation/esfurn/athena [honeur]: " HONEUR_THERAPEUTIC_AREA
done
HONEUR_THERAPEUTIC_AREA=${HONEUR_THERAPEUTIC_AREA:-honeur}

if [ "$HONEUR_THERAPEUTIC_AREA" = "honeur" ]; then
    HONEUR_THERAPEUTIC_AREA_DOMAIN=honeur.org
    HONEUR_THERAPEUTIC_AREA_URL=harbor-uat.$HONEUR_THERAPEUTIC_AREA_DOMAIN
elif [ "$HONEUR_THERAPEUTIC_AREA" = "phederation" ]; then
    HONEUR_THERAPEUTIC_AREA_DOMAIN=phederation.org
    HONEUR_THERAPEUTIC_AREA_URL=harbor-uat.$HONEUR_THERAPEUTIC_AREA_DOMAIN
elif [ "$HONEUR_THERAPEUTIC_AREA" = "esfurn" ]; then
    HONEUR_THERAPEUTIC_AREA_DOMAIN=esfurn.org
    HONEUR_THERAPEUTIC_AREA_URL=harbor-uat.$HONEUR_THERAPEUTIC_AREA_DOMAIN
elif [ "$HONEUR_THERAPEUTIC_AREA" = "athena" ]; then
    HONEUR_THERAPEUTIC_AREA_DOMAIN=athenafederation.org
    HONEUR_THERAPEUTIC_AREA_URL=harbor-uat.$HONEUR_THERAPEUTIC_AREA_DOMAIN
fi

read -p "Enter email address used to login to https://portal-uat.$HONEUR_THERAPEUTIC_AREA_DOMAIN: " HONEUR_EMAIL_ADDRESS
while [[ "$HONEUR_EMAIL_ADDRESS" == "" ]]; do
    echo "Email address can not be empty"
    read -p "Enter email address used to login to https://portal-uat.$HONEUR_THERAPEUTIC_AREA_DOMAIN: " HONEUR_EMAIL_ADDRESS
done
echo "Surf to https://$HONEUR_THERAPEUTIC_AREA_URL and login using the button \"LOGIN VIA OIDC PROVIDER\". Then click your account name on the top right corner of the screen and click \"User Profile\". Copy the CLI secret by clicking the copy symbol next to the text field."
read -p 'Enter the CLI Secret: ' HONEUR_CLI_SECRET
while [[ "$HONEUR_CLI_SECRET" == "" ]]; do
    echo "CLI Secret can not be empty"
    read -p "Enter the CLI Secret: " HONEUR_CLI_SECRET
done

echo "This script will install version 2.0.1 of the $HONEUR_THERAPEUTIC_AREA database. All $HONEUR_THERAPEUTIC_AREA docker containers will be restarted after running this script."

read -p "Enter password for $HONEUR_THERAPEUTIC_AREA database user [$HONEUR_PASSWORD]: " HONEUR_PASSWORD
read -p "Enter password for ${HONEUR_THERAPEUTIC_AREA}_admin database user [$HONEUR_ADMIN_PASSWORD]: " HONEUR_ADMIN_PASSWORD

touch postgres.env

echo "HONEUR_USER_USERNAME=$HONEUR_THERAPEUTIC_AREA" > postgres.env
echo "HONEUR_USER_PW=$HONEUR_PASSWORD" >> postgres.env
echo "HONEUR_ADMIN_USER_USERNAME=${HONEUR_THERAPEUTIC_AREA}_admin" >> postgres.env
echo "HONEUR_ADMIN_USER_PW=$HONEUR_ADMIN_PASSWORD" >> postgres.env

echo "Stop and remove postgres container if exists"
docker stop postgres > /dev/null 2>&1 || true
docker rm postgres > /dev/null 2>&1 || true

echo "Removing existing helper volumes"
docker volume rm shared > /dev/null 2>&1 || true

echo "Create $HONEUR_THERAPEUTIC_AREA-net network if it does not exists"
docker network create --driver bridge $HONEUR_THERAPEUTIC_AREA-net > /dev/null 2>&1 || true

echo "Pull $HONEUR_THERAPEUTIC_AREA/postgres:$TAG from https://$HONEUR_THERAPEUTIC_AREA_URL. This could take a while if not present on machine..."
echo "$HONEUR_CLI_SECRET" | docker login https://$HONEUR_THERAPEUTIC_AREA_URL --username $HONEUR_EMAIL_ADDRESS --password-stdin
docker pull $HONEUR_THERAPEUTIC_AREA_URL/$HONEUR_THERAPEUTIC_AREA/postgres:$TAG

echo "Creating helper volumes"
docker volume create shared > /dev/null 2>&1 || true
docker volume create pgdata > /dev/null 2>&1 || true

echo "Run $HONEUR_THERAPEUTIC_AREA/postgres:$TAG container. This could take a while..."
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
$HONEUR_THERAPEUTIC_AREA_URL/$HONEUR_THERAPEUTIC_AREA/postgres:$TAG > /dev/null 2>&1

echo "Connect postgres to $HONEUR_THERAPEUTIC_AREA-net network"
docker network connect $HONEUR_THERAPEUTIC_AREA-net postgres > /dev/null 2>&1

echo "Clean up helper files"
rm -rf postgres.env

echo "Done"

echo "Restarting $HONEUR_THERAPEUTIC_AREA Components"
docker restart webapi > /dev/null 2>&1 || true
docker restart user-mgmt > /dev/null 2>&1 || true
docker restart zeppelin > /dev/null 2>&1 || true
docker restart $HONEUR_THERAPEUTIC_AREA-studio > /dev/null 2>&1 || true
docker restart $HONEUR_THERAPEUTIC_AREA-studio-chronicle > /dev/null 2>&1 || true