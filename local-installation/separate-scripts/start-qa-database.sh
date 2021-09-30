#!/usr/bin/env bash
set -e

cr=$(echo $'\n.')
cr=${cr%.}

read -p 'Enter the Therapeutic Area of choice. Enter honeur/phederation/esfurn/athena [honeur]: ' FEDER8_THERAPEUTIC_AREA
while [[ "$FEDER8_THERAPEUTIC_AREA" != "honeur" && "$FEDER8_THERAPEUTIC_AREA" != "phederation" && "$FEDER8_THERAPEUTIC_AREA" != "esfurn" && "$FEDER8_THERAPEUTIC_AREA" != "athena" && "$FEDER8_THERAPEUTIC_AREA" != "" ]]; do
    echo "Enter \"honeur\", \"phederation\", \"esfurn\", \"athena\" or empty for default \"honeur\" value"
    read -p "Enter the Therapeutic Area of choice. Enter honeur/phederation/esfurn/athena [honeur]: " FEDER8_THERAPEUTIC_AREA
done
FEDER8_THERAPEUTIC_AREA=${FEDER8_THERAPEUTIC_AREA:-honeur}

if [ "$FEDER8_THERAPEUTIC_AREA" = "honeur" ]; then
    FEDER8_THERAPEUTIC_AREA_DOMAIN=honeur.org
    FEDER8_THERAPEUTIC_AREA_URL=harbor-dev.$FEDER8_THERAPEUTIC_AREA_DOMAIN
elif [ "$FEDER8_THERAPEUTIC_AREA" = "phederation" ]; then
    FEDER8_THERAPEUTIC_AREA_DOMAIN=phederation.org
    FEDER8_THERAPEUTIC_AREA_URL=harbor-dev.$FEDER8_THERAPEUTIC_AREA_DOMAIN
elif [ "$FEDER8_THERAPEUTIC_AREA" = "esfurn" ]; then
    FEDER8_THERAPEUTIC_AREA_DOMAIN=esfurn.org
    FEDER8_THERAPEUTIC_AREA_URL=harbor-dev.$FEDER8_THERAPEUTIC_AREA_DOMAIN
elif [ "$FEDER8_THERAPEUTIC_AREA" = "athena" ]; then
    FEDER8_THERAPEUTIC_AREA_DOMAIN=athenafederation.org
    FEDER8_THERAPEUTIC_AREA_URL=harbor-dev.$FEDER8_THERAPEUTIC_AREA_DOMAIN
fi

FEDER8_THERAPEUTIC_AREA_UPPERCASE=$(echo "$FEDER8_THERAPEUTIC_AREA" |  tr '[:lower:]' '[:upper:]' )

read -p "Enter email address used to login to https://portal-dev.${FEDER8_THERAPEUTIC_AREA_DOMAIN}: " FEDER8_EMAIL_ADDRESS
while [[ "$FEDER8_EMAIL_ADDRESS" == "" ]]; do
    echo "Email address can not be empty"
    read -p "Enter email address used to login to https://portal-dev.$FEDER8_THERAPEUTIC_AREA_DOMAIN: " FEDER8_EMAIL_ADDRESS
done
read -p "Surf to https://$FEDER8_THERAPEUTIC_AREA_URL and login using the button \"LOGIN VIA OIDC PROVIDER\". Then click your account name on the top right corner of the screen and click \"User Profile\". Copy the CLI secret by clicking the copy symbol next to the text field.${cr}Enter the CLI Secret: " FEDER8_CLI_SECRET
while [[ "$FEDER8_CLI_SECRET" == "" ]]; do
    echo "CLI Secret can not be empty"
    read -p "Enter the CLI Secret: " FEDER8_CLI_SECRET
done

echo "Stop and remove postgres-qa container if exists"
docker stop postgres-qa > /dev/null 2>&1 || true
docker rm postgres-qa > /dev/null 2>&1 || true

docker stop webapi-source-qa-enable > /dev/null 2>&1 || true
docker rm webapi-source-qa-enable > /dev/null 2>&1 || true

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/local-installation/separate-scripts/start-postgres.sh --output start-postgres.sh
chmod +x start-postgres.sh
export FEDER8_SHARED_SECRETS_VOLUME_NAME=shared-qa
export FEDER8_PGDATA_VOLUME_NAME=pgdata-qa
export FEDER8_POSTGRES_CONTAINER_NAME=postgres-qa
export FEDER8_RESTART_OTHER_COMPONENTS=false
export FEDER8_CONTAINER_HOST_PORT=5445
{
  echo "$FEDER8_THERAPEUTIC_AREA";
  echo "$FEDER8_EMAIL_ADDRESS";
  echo "$FEDER8_CLI_SECRET";
  echo "$FEDER8_NEW_PASSWORD";
  echo "$FEDER8_NEW_ADMIN_PASSWORD"
} | ./start-postgres.sh
rm -rf start-postgres.sh

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/local-installation/separate-scripts/start-source-creation.sh --output start-source-creation.sh
chmod +x start-source-creation.sh
export FEDER8_SHARED_SECRETS_VOLUME_NAME=shared-qa
{
  echo "$FEDER8_THERAPEUTIC_AREA";
  echo "$FEDER8_EMAIL_ADDRESS";
  echo "$FEDER8_CLI_SECRET";
  echo "postgres-qa";
  echo "${FEDER8_THERAPEUTIC_AREA_UPPERCASE} QA OMOP CDM";
  echo "2"
} | ./start-source-creation.sh
rm -rf start-source-creation.sh
