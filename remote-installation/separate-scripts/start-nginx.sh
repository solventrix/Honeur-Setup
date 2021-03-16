#!/usr/bin/env bash
set -e

VERSION=2.0.2
TAG=$VERSION

read -p "Enter the Therapeutic Area of choice. Enter honeur/phederation/esfurn/athena [honeur]: " HONEUR_THERAPEUTIC_AREA
while [[ "$HONEUR_THERAPEUTIC_AREA" != "honeur" && "$HONEUR_THERAPEUTIC_AREA" != "phederation" && "$HONEUR_THERAPEUTIC_AREA" != "esfurn" && "$HONEUR_THERAPEUTIC_AREA" != "athena" && "$HONEUR_THERAPEUTIC_AREA" != "" ]]; do
    echo "Enter \"honeur\", \"phederation\", \"esfurn\", \"athena\" or empty for default \"honeur\" value"
    read -p "Enter the Therapeutic Area of choice. Enter honeur/phederation/esfurn/athena [honeur]: " HONEUR_THERAPEUTIC_AREA
done
HONEUR_THERAPEUTIC_AREA=${HONEUR_THERAPEUTIC_AREA:-honeur}

if [ "$HONEUR_THERAPEUTIC_AREA" = "honeur" ]; then
    HONEUR_THERAPEUTIC_AREA_DOMAIN=honeur.org
    HONEUR_THERAPEUTIC_AREA_URL=harbor-uat.$HONEUR_THERAPEUTIC_AREA_DOMAIN
    HONEUR_CHANGE_THERAPEUTIC_AREA_LIGHT_THEME_COLOR=\#0794e0
    HONEUR_CHANGE_THERAPEUTIC_AREA_DARK_THEME_COLOR=\#002562
elif [ "$HONEUR_THERAPEUTIC_AREA" = "phederation" ]; then
    HONEUR_THERAPEUTIC_AREA_DOMAIN=phederation.org
    HONEUR_THERAPEUTIC_AREA_URL=harbor-uat.$HONEUR_THERAPEUTIC_AREA_DOMAIN
    HONEUR_CHANGE_THERAPEUTIC_AREA_LIGHT_THEME_COLOR=\#3590d5
    HONEUR_CHANGE_THERAPEUTIC_AREA_DARK_THEME_COLOR=\#0741ad
elif [ "$HONEUR_THERAPEUTIC_AREA" = "esfurn" ]; then
    HONEUR_THERAPEUTIC_AREA_DOMAIN=esfurn.org
    HONEUR_THERAPEUTIC_AREA_URL=harbor-uat.$HONEUR_THERAPEUTIC_AREA_DOMAIN
    HONEUR_CHANGE_THERAPEUTIC_AREA_LIGHT_THEME_COLOR=\#668772
    HONEUR_CHANGE_THERAPEUTIC_AREA_DARK_THEME_COLOR=\#44594c
elif [ "$HONEUR_THERAPEUTIC_AREA" = "athena" ]; then
    HONEUR_THERAPEUTIC_AREA_DOMAIN=athenafederation.org
    HONEUR_THERAPEUTIC_AREA_URL=harbor-uat.$HONEUR_THERAPEUTIC_AREA_DOMAIN
    HONEUR_CHANGE_THERAPEUTIC_AREA_LIGHT_THEME_COLOR=\#0794e0
    HONEUR_CHANGE_THERAPEUTIC_AREA_DARK_THEME_COLOR=\#002562
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

touch nginx.env

echo "HONEUR_THERAPEUTIC_AREA=$HONEUR_THERAPEUTIC_AREA" >> nginx.env
echo "HONEUR_CHANGE_THERAPEUTIC_AREA_LIGHT_THEME_COLOR=$HONEUR_CHANGE_THERAPEUTIC_AREA_LIGHT_THEME_COLOR" >> nginx.env
echo "HONEUR_CHANGE_THERAPEUTIC_AREA_DARK_THEME_COLOR=$HONEUR_CHANGE_THERAPEUTIC_AREA_DARK_THEME_COLOR" >> nginx.env

if [ "$( docker container inspect -f '{{.State.Running}}' webapi )" == "true" ]; then
    echo "ATLAS_ENABLED=true" >> nginx.env
    echo "ATLAS_URL=/atlas" >> nginx.env
fi

if [ "$( docker container inspect -f '{{.State.Running}}' zeppelin )" == "true" ]; then
    echo "ZEPPELIN_ENABLED=true" >> nginx.env
    echo "ZEPPELIN_URL=/zeppelin/" >> nginx.env
fi

if [ "$( docker container inspect -f '{{.State.Running}}' user-mgmt )" == "true" ]; then
    echo "USER_MANAGEMENT_ENABLED=true" >> nginx.env
    echo "USER_MANAGEMENT_URL=/user-mgmt/" >> nginx.env
fi

if [ "$( docker container inspect -f '{{.State.Running}}' $HONEUR_THERAPEUTIC_AREA-studio )" == "true" ]; then
    echo "HONEUR_STUDIO_ENABLED=true" >> nginx.env
    echo "HONEUR_THERAPEUTIC_AREA=$HONEUR_THERAPEUTIC_AREA" >> nginx.env
    echo "RSTUDIO_URL=/$HONEUR_THERAPEUTIC_AREA-studio/app/rstudio" >> nginx.env
    echo "VSCODE_URL=/$HONEUR_THERAPEUTIC_AREA-studio/app/vscode" >> nginx.env
    echo "REPORTS_URL=/$HONEUR_THERAPEUTIC_AREA-studio/app/reports" >> nginx.env
    echo "PERSONAL_URL=/$HONEUR_THERAPEUTIC_AREA-studio/app/personal" >> nginx.env
    echo "DOCUMENTS_URL=/$HONEUR_THERAPEUTIC_AREA-studio/app/documents" >> nginx.env
fi

echo "Stop and remove nginx container if exists"
docker stop nginx > /dev/null 2>&1 || true
docker rm nginx > /dev/null 2>&1 || true

echo "Create $HONEUR_THERAPEUTIC_AREA-net network if it does not exists"
docker network create --driver bridge $HONEUR_THERAPEUTIC_AREA-net > /dev/null 2>&1 || true

echo "Pull $HONEUR_THERAPEUTIC_AREA/nginx:$TAG from https://$HONEUR_THERAPEUTIC_AREA_URL. This could take a while if not present on machine"
echo "$HONEUR_CLI_SECRET" | docker login https://$HONEUR_THERAPEUTIC_AREA_URL --username $HONEUR_EMAIL_ADDRESS --password-stdin
docker pull $HONEUR_THERAPEUTIC_AREA_URL/$HONEUR_THERAPEUTIC_AREA/nginx:$TAG

echo "Run $HONEUR_THERAPEUTIC_AREA/nginx:$TAG container. This could take a while..."
docker run \
--name "nginx" \
-p "80:8080" \
--restart on-failure:5 \
--security-opt no-new-privileges \
--env-file nginx.env \
--network $HONEUR_THERAPEUTIC_AREA-net \
-m "500m" \
--cpus "1" \
--pids-limit 100 \
--cpu-shares 1024 \
--ulimit nofile=1024:1024 \
-d \
$HONEUR_THERAPEUTIC_AREA_URL/$HONEUR_THERAPEUTIC_AREA/nginx:$TAG > /dev/null 2>&1

echo "Clean up helper files"
rm -rf nginx.env

echo "Done"