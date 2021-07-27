#!/usr/bin/env bash
set -e

cr=$(echo $'\n.')
cr=${cr%.}

VERSION=2.0.2
TAG=$VERSION

read -p "Enter the Therapeutic Area of choice. Enter honeur/phederation/esfurn/athena [honeur]: " FEDER8_THERAPEUTIC_AREA
while [[ "$FEDER8_THERAPEUTIC_AREA" != "honeur" && "$FEDER8_THERAPEUTIC_AREA" != "phederation" && "$FEDER8_THERAPEUTIC_AREA" != "esfurn" && "$FEDER8_THERAPEUTIC_AREA" != "athena" && "$FEDER8_THERAPEUTIC_AREA" != "" ]]; do
    echo "Enter \"honeur\", \"phederation\", \"esfurn\", \"athena\" or empty for default \"honeur\" value"
    read -p "Enter the Therapeutic Area of choice. Enter honeur/phederation/esfurn/athena [honeur]: " FEDER8_THERAPEUTIC_AREA
done
FEDER8_THERAPEUTIC_AREA=${FEDER8_THERAPEUTIC_AREA:-honeur}

if [ "$FEDER8_THERAPEUTIC_AREA" = "honeur" ]; then
    FEDER8_THERAPEUTIC_AREA_DOMAIN=honeur.org
    FEDER8_THERAPEUTIC_AREA_URL=harbor-uat.$FEDER8_THERAPEUTIC_AREA_DOMAIN
    FEDER8_CHANGE_THERAPEUTIC_AREA_LIGHT_THEME_COLOR=\#0794e0
    FEDER8_CHANGE_THERAPEUTIC_AREA_DARK_THEME_COLOR=\#002562
elif [ "$FEDER8_THERAPEUTIC_AREA" = "phederation" ]; then
    FEDER8_THERAPEUTIC_AREA_DOMAIN=phederation.org
    FEDER8_THERAPEUTIC_AREA_URL=harbor-uat.$FEDER8_THERAPEUTIC_AREA_DOMAIN
    FEDER8_CHANGE_THERAPEUTIC_AREA_LIGHT_THEME_COLOR=\#3590d5
    FEDER8_CHANGE_THERAPEUTIC_AREA_DARK_THEME_COLOR=\#0741ad
elif [ "$FEDER8_THERAPEUTIC_AREA" = "esfurn" ]; then
    FEDER8_THERAPEUTIC_AREA_DOMAIN=esfurn.org
    FEDER8_THERAPEUTIC_AREA_URL=harbor-uat.$FEDER8_THERAPEUTIC_AREA_DOMAIN
    FEDER8_CHANGE_THERAPEUTIC_AREA_LIGHT_THEME_COLOR=\#668772
    FEDER8_CHANGE_THERAPEUTIC_AREA_DARK_THEME_COLOR=\#44594c
elif [ "$FEDER8_THERAPEUTIC_AREA" = "athena" ]; then
    FEDER8_THERAPEUTIC_AREA_DOMAIN=athenafederation.org
    FEDER8_THERAPEUTIC_AREA_URL=harbor-uat.$FEDER8_THERAPEUTIC_AREA_DOMAIN
    FEDER8_CHANGE_THERAPEUTIC_AREA_LIGHT_THEME_COLOR=\#0794e0
    FEDER8_CHANGE_THERAPEUTIC_AREA_DARK_THEME_COLOR=\#002562
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

touch nginx.env

echo "HONEUR_THERAPEUTIC_AREA=$FEDER8_THERAPEUTIC_AREA" >> nginx.env
echo "HONEUR_CHANGE_THERAPEUTIC_AREA_LIGHT_THEME_COLOR=$FEDER8_CHANGE_THERAPEUTIC_AREA_LIGHT_THEME_COLOR" >> nginx.env
echo "HONEUR_CHANGE_THERAPEUTIC_AREA_DARK_THEME_COLOR=$FEDER8_CHANGE_THERAPEUTIC_AREA_DARK_THEME_COLOR" >> nginx.env

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

if [ "$( docker container inspect -f '{{.State.Running}}' $FEDER8_THERAPEUTIC_AREA-studio )" == "true" ]; then
    echo "HONEUR_STUDIO_ENABLED=true" >> nginx.env
    echo "HONEUR_THERAPEUTIC_AREA=$FEDER8_THERAPEUTIC_AREA" >> nginx.env
    echo "RSTUDIO_URL=/$FEDER8_THERAPEUTIC_AREA-studio/app/rstudio" >> nginx.env
    echo "VSCODE_URL=/$FEDER8_THERAPEUTIC_AREA-studio/app/vscode" >> nginx.env
    echo "REPORTS_URL=/$FEDER8_THERAPEUTIC_AREA-studio/app/reports" >> nginx.env
    echo "PERSONAL_URL=/$FEDER8_THERAPEUTIC_AREA-studio/app/personal" >> nginx.env
    echo "DOCUMENTS_URL=/$FEDER8_THERAPEUTIC_AREA-studio/app/documents" >> nginx.env
fi

echo "Stop and remove nginx container if exists"
docker stop nginx > /dev/null 2>&1 || true
docker rm nginx > /dev/null 2>&1 || true

echo "Create $FEDER8_THERAPEUTIC_AREA-net network if it does not exists"
docker network create --driver bridge $FEDER8_THERAPEUTIC_AREA-net > /dev/null 2>&1 || true

echo "Pull $FEDER8_THERAPEUTIC_AREA/nginx:$TAG from https://$FEDER8_THERAPEUTIC_AREA_URL. This could take a while if not present on machine"
echo "$FEDER8_CLI_SECRET" | docker login https://$FEDER8_THERAPEUTIC_AREA_URL --username $FEDER8_EMAIL_ADDRESS --password-stdin
docker pull $FEDER8_THERAPEUTIC_AREA_URL/$FEDER8_THERAPEUTIC_AREA/nginx:$TAG

echo "Run $FEDER8_THERAPEUTIC_AREA/nginx:$TAG container. This could take a while..."
docker run \
--name "nginx" \
-p "80:8080" \
--restart on-failure:5 \
--security-opt no-new-privileges \
--env-file nginx.env \
--network $FEDER8_THERAPEUTIC_AREA-net \
-m "500m" \
--cpus "1" \
--pids-limit 100 \
--cpu-shares 1024 \
--ulimit nofile=1024:1024 \
-d \
$FEDER8_THERAPEUTIC_AREA_URL/$FEDER8_THERAPEUTIC_AREA/nginx:$TAG > /dev/null 2>&1

echo "Clean up helper files"
rm -rf nginx.env

echo "Done"