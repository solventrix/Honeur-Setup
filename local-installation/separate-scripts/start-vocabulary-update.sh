#!/usr/bin/env bash
set -e

cr=$(echo $'\n.')
cr=${cr%.}

VERSION=2.0.2
TAG=pipeline-vocabulary-update-$VERSION

read -p 'Enter the Therapeutic Area of choice. Enter honeur/phederation/esfurn [honeur]: ' FEDER8_THERAPEUTIC_AREA
while [[ "$FEDER8_THERAPEUTIC_AREA" != "honeur" && "$FEDER8_THERAPEUTIC_AREA" != "phederation" && "$FEDER8_THERAPEUTIC_AREA" != "esfurn" && "$FEDER8_THERAPEUTIC_AREA" != "" ]]; do
    echo "Enter \"honeur\", \"phederation\", \"esfurn\" or empty for default \"honeur\" value"
    read -p "Enter the Therapeutic Area of choice. Enter honeur/phederation/esfurn [honeur]: " FEDER8_THERAPEUTIC_AREA
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

touch pipeline-vocabulary-update.env

echo "DB_HOST=postgres" >> pipeline-vocabulary-update.env
echo "THERAPEUTIC_AREA=$FEDER8_THERAPEUTIC_AREA" >> pipeline-vocabulary-update.env
echo "THERAPEUTIC_AREA_URL=$FEDER8_THERAPEUTIC_AREA_URL" >> pipeline-vocabulary-update.env
echo "DOCKER_USERNAME=$FEDER8_EMAIL_ADDRESS" >> pipeline-vocabulary-update.env
echo "DOCKER_PASSWORD=$FEDER8_CLI_SECRET" >> pipeline-vocabulary-update.env

echo "Pull $FEDER8_THERAPEUTIC_AREA/postgres:$TAG from https://$FEDER8_THERAPEUTIC_AREA_URL. This could take a while if not present on machine"
echo "$FEDER8_CLI_SECRET" | docker login https://$FEDER8_THERAPEUTIC_AREA_URL --username $FEDER8_EMAIL_ADDRESS --password-stdin
docker pull $FEDER8_THERAPEUTIC_AREA_URL/$FEDER8_THERAPEUTIC_AREA/postgres:$TAG

echo "Run $FEDER8_THERAPEUTIC_AREA/postgres:$TAG container. This could take a while..."
docker run \
--rm \
--name pipeline-vocabulary-update \
-v shared:/var/lib/shared \
-v /var/run/docker.sock:/var/run/docker.sock \
--env-file pipeline-vocabulary-update.env \
--network feder8-net \
$FEDER8_THERAPEUTIC_AREA_URL/$FEDER8_THERAPEUTIC_AREA/postgres:$TAG

echo "Clean up helper files"
rm -rf pipeline-vocabulary-update.env

echo "Done"
