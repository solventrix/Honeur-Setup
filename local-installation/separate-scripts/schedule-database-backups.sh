#!/usr/bin/env bash
set -e

VERSION=2.0.0
BACKUP_FOLDER=${PWD}/backup

if [ -z "$1" ]
then
  read -p "Enter the name of the database to backup: " DB_NAME
else
  DB_NAME=$1
fi

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

echo "Stop and remove backup-$DB_NAME container if exists"
docker stop backup-$DB_NAME > /dev/null 2>&1 || true
docker rm backup-$DB_NAME > /dev/null 2>&1 || true

echo "Pull $FEDER8_THERAPEUTIC_AREA/scheduled-backup:$VERSION from https://$FEDER8_THERAPEUTIC_AREA_URL. This could take a while if not present on machine"
echo "$FEDER8_CLI_SECRET" | docker login https://$FEDER8_THERAPEUTIC_AREA_URL --username $FEDER8_EMAIL_ADDRESS --password-stdin
docker pull $FEDER8_THERAPEUTIC_AREA_URL/$FEDER8_THERAPEUTIC_AREA/scheduled-backup:$VERSION

echo "Run $FEDER8_THERAPEUTIC_AREA/scheduled-backup:$VERSION container. This could take a while..."
docker run \
  --name "backup-$DB_NAME" \
  --restart on-failure:5 \
  --network="feder8-net" \
  -e DB_NAME=$DB_NAME \
  -v "shared:/var/lib/shared:ro" \
  -v ${BACKUP_FOLDER}:/backup \
  -d \
  honeur/scheduled-backup:$VERSION

echo "Done"




