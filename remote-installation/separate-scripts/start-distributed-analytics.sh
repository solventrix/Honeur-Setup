#!/usr/bin/env bash
set -e

cr=$(echo $'\n.')
cr=${cr%.}

VERSION_REMOTE=2.0.1
TAG_REMOTE=remote-$VERSION_REMOTE

VERSION_R_SERVER=2.0.3
TAG_R_SERVER=r-server-$VERSION_R_SERVER

CURRENT_DIRECTORY=$(pwd)

read -p "Enter the Therapeutic Area of choice. Enter honeur/phederation/esfurn/athena [honeur]: " FEDER8_THERAPEUTIC_AREA
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
read -p "Surf to https://$FEDER8_THERAPEUTIC_AREA_URL and login using the button \"LOGIN VIA OIDC PROVIDER\". Then click your account name on the top right corner of the screen and click \"User Profile\". Copy the CLI secret by clicking the copy symbol next to the text field.${cr}Enter the CLI Secret: " FEDER8_CLI_SECRET
while [[ "$FEDER8_CLI_SECRET" == "" ]]; do
    echo "CLI Secret can not be empty"
    read -p "Enter the CLI Secret: " FEDER8_CLI_SECRET
done

read -p "Enter the directory where Zeppelin will save the prepared distributed analytics data [$CURRENT_DIRECTORY/distributed-analytics]: " FEDER8_ANALYTICS_SHARED_FOLDER
FEDER8_ANALYTICS_SHARED_FOLDER=${FEDER8_ANALYTICS_SHARED_FOLDER:-$CURRENT_DIRECTORY/distributed-analytics}
read -p "Enter your $FEDER8_THERAPEUTIC_AREA organization [Janssen]: " FEDER8_ANALYTICS_ORGANIZATION
FEDER8_ANALYTICS_ORGANIZATION=${FEDER8_ANALYTICS_ORGANIZATION:-Janssen}

touch distributed-analytics.env

echo "DISTRIBUTED_SERVICE_CLIENT_SCHEME=https" >> distributed-analytics.env
echo "DISTRIBUTED_SERVICE_CLIENT_HOST=distributed-analytics.$FEDER8_THERAPEUTIC_AREA_DOMAIN" >> distributed-analytics.env
echo "DISTRIBUTED_SERVICE_CLIENT_PORT=443" >> distributed-analytics.env
echo "DISTRIBUTED_SERVICE_CLIENT_BIND=distributed-service" >> distributed-analytics.env
echo "DISTRIBUTED_SERVICE_CLIENT_API=api" >> distributed-analytics.env
echo "WEBAPI_CLIENT_SCHEME=http" >> distributed-analytics.env
echo "WEBAPI_CLIENT_HOST=webapi" >> distributed-analytics.env
echo "WEBAPI_CLIENT_PORT=8080" >> distributed-analytics.env
echo "WEBAPI_CLIENT_BIND=webapi" >> distributed-analytics.env
echo "WEBAPI_CLIENT_API=" >> distributed-analytics.env
echo "R_SERVER_CLIENT_SCHEME=http" >> distributed-analytics.env
echo "R_SERVER_CLIENT_HOST=distributed-analytics-r-server" >> distributed-analytics.env
echo "R_SERVER_CLIENT_PORT=8080" >> distributed-analytics.env
echo "R_SERVER_CLIENT_BIND=" >> distributed-analytics.env
echo "R_SERVER_CLIENT_API=" >> distributed-analytics.env
echo "HONEUR_ANALYTICS_ORGANIZATION=$FEDER8_ANALYTICS_ORGANIZATION" >> distributed-analytics.env

echo "Stop and remove distributed analytics containers if exists"
docker stop $(docker ps --filter 'network=$FEDER8_THERAPEUTIC_AREA-distributed-analytics-net' -q -a) > /dev/null 2>&1 || true
docker rm $(docker ps --filter 'network=$FEDER8_THERAPEUTIC_AREA-distributed-analytics-net' -q -a) > /dev/null 2>&1 || true

echo "Create $FEDER8_THERAPEUTIC_AREA-net network if it does not exists"
docker network create --driver bridge $FEDER8_THERAPEUTIC_AREA-net > /dev/null 2>&1 || true
echo "Create $FEDER8_THERAPEUTIC_AREA-distributed-analytics-net network if it does not exists"
docker network create --driver bridge $FEDER8_THERAPEUTIC_AREA-distributed-analytics-net > /dev/null 2>&1 || true


echo "Pull $FEDER8_THERAPEUTIC_AREA/distributed-analytics:$TAG_R_SERVER from docker hub. This could take a while if not present on machine"
echo "$FEDER8_CLI_SECRET" | docker login https://$FEDER8_THERAPEUTIC_AREA_URL --username $FEDER8_EMAIL_ADDRESS --password-stdin
docker pull $FEDER8_THERAPEUTIC_AREA_URL/$FEDER8_THERAPEUTIC_AREA/distributed-analytics:$TAG_R_SERVER
echo "Pull $FEDER8_THERAPEUTIC_AREA/distributed-analytics:$TAG_REMOTE from docker hub. This could take a while if not present on machine"
echo "$FEDER8_CLI_SECRET" | docker login https://$FEDER8_THERAPEUTIC_AREA_URL --username $FEDER8_EMAIL_ADDRESS --password-stdin
docker pull $FEDER8_THERAPEUTIC_AREA_URL/$FEDER8_THERAPEUTIC_AREA/distributed-analytics:$TAG_REMOTE

echo "Run $FEDER8_THERAPEUTIC_AREA/distributed-analytics:$TAG_R_SERVER container. This could take a while..."
docker run \
--name "distributed-analytics-r-server" \
--restart on-failure:5 \
--security-opt no-new-privileges \
-v "$FEDER8_ANALYTICS_SHARED_FOLDER:/usr/local/src/datafiles" \
-m "1g" \
--cpus "2" \
--pids-limit 100 \
--cpu-shares 1024 \
--ulimit nofile=1024:1024 \
-d \
$FEDER8_THERAPEUTIC_AREA_URL/$FEDER8_THERAPEUTIC_AREA/distributed-analytics:$TAG_R_SERVER > /dev/null 2>&1

echo "Connect distributed-analytics-r-server to $FEDER8_THERAPEUTIC_AREA-net network"
docker network connect $FEDER8_THERAPEUTIC_AREA-net distributed-analytics-r-server > /dev/null 2>&1
echo "Connect distributed-analytics-r-server to $FEDER8_THERAPEUTIC_AREA-distributed-analytics-net network"
docker network connect $FEDER8_THERAPEUTIC_AREA-distributed-analytics-net distributed-analytics-r-server > /dev/null 2>&1

echo "Run ${FEDER8_THERAPEUTIC_AREA}/distributed-analytics:$TAG_REMOTE container. This could take a while..."
docker run \
--name "distributed-analytics-remote" \
--restart on-failure:5 \
--security-opt no-new-privileges \
--env-file distributed-analytics.env \
-m "1g" \
--cpus "2" \
--pids-limit 100 \
--cpu-shares 1024 \
--ulimit nofile=1024:1024 \
-d \
$FEDER8_THERAPEUTIC_AREA_URL/$FEDER8_THERAPEUTIC_AREA/distributed-analytics:$TAG_REMOTE > /dev/null 2>&1

echo "Connect distributed-analytics-remote to $FEDER8_THERAPEUTIC_AREA-net network"
docker network connect $FEDER8_THERAPEUTIC_AREA-net distributed-analytics-remote > /dev/null 2>&1
echo "Connect distributed-analytics-remote to $FEDER8_THERAPEUTIC_AREA-distributed-analytics-net network"
docker network connect $FEDER8_THERAPEUTIC_AREA-distributed-analytics-net distributed-analytics-remote > /dev/null 2>&1

echo "Clean up helper files"
rm -rf distributed-analytics.env

echo "Done"