#!/usr/bin/env bash
set -e

cr=$(echo $'\n.')
cr=${cr%.}

VERSION=2.0.3
TAG=$VERSION
CURRENT_DIRECTORY=$(pwd)

read -p "Enter the Therapeutic Area of choice. Enter honeur/phederation/esfurn/athena [honeur]: " FEDER8_THERAPEUTIC_AREA
while [[ "$FEDER8_THERAPEUTIC_AREA" != "honeur" && "$FEDER8_THERAPEUTIC_AREA" != "phederation" && "$FEDER8_THERAPEUTIC_AREA" != "esfurn" && "$FEDER8_THERAPEUTIC_AREA" != "athena" && "$FEDER8_THERAPEUTIC_AREA" != "" ]]; do
    echo "Enter \"honeur\", \"phederation\", \"esfurn\", \"athena\" or empty for default \"honeur\" value"
    read -p "Enter the Therapeutic Area of choice. Enter honeur/phederation/esfurn/athena [honeur]: " FEDER8_THERAPEUTIC_AREA
done
FEDER8_THERAPEUTIC_AREA=${FEDER8_THERAPEUTIC_AREA:-honeur}
FEDER8_THERAPEUTIC_AREA_UPPERCASE=$(echo "$FEDER8_THERAPEUTIC_AREA" |  tr '[:lower:]' '[:upper:]' )

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


read -p "Enter the folder containing the certificates [$CURRENT_DIRECTORY/certificates]: " CERTIFICATE_FOLDER
CERTIFICATE_FOLDER=${CERTIFICATE_FOLDER:-$CURRENT_DIRECTORY/certificates}
if [ -d "$CERTIFICATE_FOLDER" ]; then
    mkdir -p $CERTIFICATE_FOLDER/$FEDER8_THERAPEUTIC_AREA-studio
    rm -rf $CERTIFICATE_FOLDER/$FEDER8_THERAPEUTIC_AREA-studio/*
    if [ -f "$CERTIFICATE_FOLDER/$FEDER8_THERAPEUTIC_AREA-studio-client-key.pem" ]; then
        cp -v $CERTIFICATE_FOLDER/$FEDER8_THERAPEUTIC_AREA-studio-client-key.pem $CERTIFICATE_FOLDER/$FEDER8_THERAPEUTIC_AREA-studio/key.pem
        cp -v $CERTIFICATE_FOLDER/$FEDER8_THERAPEUTIC_AREA-studio-client-cert.pem $CERTIFICATE_FOLDER/$FEDER8_THERAPEUTIC_AREA-studio/cert.pem
        cp -v $CERTIFICATE_FOLDER/ca.pem $CERTIFICATE_FOLDER/$FEDER8_THERAPEUTIC_AREA-studio/ca.pem
        chmod -v 0400 $CERTIFICATE_FOLDER/$FEDER8_THERAPEUTIC_AREA-studio/key.pem
        chmod -v 0444 $CERTIFICATE_FOLDER/$FEDER8_THERAPEUTIC_AREA-studio/cert.pem
    elif [ -f "$CERTIFICATE_FOLDER/key.pem" ]; then
        cp -v $CERTIFICATE_FOLDER/key.pem $CERTIFICATE_FOLDER/$FEDER8_THERAPEUTIC_AREA-studio/key.pem
        cp -v $CERTIFICATE_FOLDER/cert.pem $CERTIFICATE_FOLDER/$FEDER8_THERAPEUTIC_AREA-studio/cert.pem
        cp -v $CERTIFICATE_FOLDER/ca.pem $CERTIFICATE_FOLDER/$FEDER8_THERAPEUTIC_AREA-studio/ca.pem
    else
        echo "Warning: '$CERTIFICATE_FOLDER' doesn't contain a client certificate for ${FEDER8_THERAPEUTIC_AREA_UPPERCASE} Studio.  Abort."
        exit
    fi
else
    echo "Warning: '$CERTIFICATE_FOLDER' NOT found.  Abort."
    exit
fi


read -p 'Enter the FQDN(Fully Qualified Domain Name eg. www.example.com) or public IP address(eg. 125.24.44.18) of the host machine. Use localhost to for testing [localhost]: ' FEDER8_HOST_MACHINE
FEDER8_HOST_MACHINE=${FEDER8_HOST_MACHINE:-localhost}

read -p "Enter the directory where ${FEDER8_THERAPEUTIC_AREA_UPPERCASE} Studio will store its data [$CURRENT_DIRECTORY/${FEDER8_THERAPEUTIC_AREA}studio]: " FEDER8_STUDIO_FOLDER
FEDER8_STUDIO_FOLDER=${FEDER8_STUDIO_FOLDER:-$CURRENT_DIRECTORY/${FEDER8_THERAPEUTIC_AREA}studio}

read -p "Enter the directory where ${FEDER8_THERAPEUTIC_AREA_UPPERCASE} Studio will save the prepared distributed analytics data [$CURRENT_DIRECTORY/distributed-analytics]: " FEDER8_ANALYTICS_SHARED_FOLDER
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

USERID=1000

touch honeur-studio.env

echo "TAG=$TAG" > honeur-studio.env
echo "APPLICATION_LOGS_TO_STDOUT=false" >> honeur-studio.env
echo "SITE_NAME=${FEDER8_THERAPEUTIC_AREA}studio" >> honeur-studio.env
echo "CONTENT_PATH=$FEDER8_STUDIO_FOLDER" >> honeur-studio.env
echo "USERID=$USERID" >> honeur-studio.env
echo "DOMAIN_NAME=$FEDER8_HOST_MACHINE" >> honeur-studio.env
echo "HONEUR_DISTRIBUTED_ANALYTICS_DATA_FOLDER=$FEDER8_ANALYTICS_SHARED_FOLDER" >> honeur-studio.env
echo "AUTHENTICATION_METHOD=$FEDER8_SECURITY_METHOD" >> honeur-studio.env
echo "HONEUR_THERAPEUTIC_AREA=$FEDER8_THERAPEUTIC_AREA" >> honeur-studio.env
echo "HONEUR_THERAPEUTIC_AREA_URL=${FEDER8_THERAPEUTIC_AREA_URL}" >> honeur-studio.env
echo "HONEUR_THERAPEUTIC_AREA_UPPERCASE=${FEDER8_THERAPEUTIC_AREA_UPPERCASE}" >> honeur-studio.env
echo "PROXY_DOCKER_URL=https://172.17.0.1:2376" >> honeur-studio.env
echo "PROXY_DOCKER_CERT_PATH=/home/certs" >> honeur-studio.env


if [ "$FEDER8_SECURITY_METHOD" = "jdbc" ]; then
    #JDBC
    echo "DATASOURCE_DRIVER_CLASS_NAME=org.postgresql.Driver" >> honeur-studio.env
    echo "DATASOURCE_URL=jdbc:postgresql://postgres:5432/OHDSI?currentSchema=webapi" >> honeur-studio.env
    echo "WEBAPI_ADMIN_USERNAME=ohdsi_admin_user" >> honeur-studio.env
elif [ "$FEDER8_SECURITY_METHOD" = "ldap" ]; then
    #LDAP
    echo "HONEUR_STUDIO_LDAP_URL=$FEDER8_SECURITY_LDAP_URL/$FEDER8_SECURITY_LDAP_BASE_DN" >> honeur-studio.env
    echo "HONEUR_STUDIO_LDAP_DN=uid={0}" >> honeur-studio.env
    echo "HONEUR_STUDIO_LDAP_MANAGER_DN=$FEDER8_SECURITY_LDAP_SYSTEM_USERNAME" >> honeur-studio.env
    echo "HONEUR_STUDIO_LDAP_MANAGER_PASSWORD=$FEDER8_SECURITY_LDAP_SYSTEM_PASSWORD" >> honeur-studio.env
fi

echo "SITE_NAME=$FEDER8_THERAPEUTIC_AREAstudio" > honeur-studio-chronicle.env
echo "USERID=$USERID" >> honeur-studio-chronicle.env
echo "USER=$FEDER8_THERAPEUTIC_AREAstudio" >> honeur-studio-chronicle.env

echo "Stop and remove all $FEDER8_THERAPEUTIC_AREA-studio containers if exists"
docker stop $(docker ps --filter "network=$FEDER8_THERAPEUTIC_AREA-studio-net" -q -a) > /dev/null 2>&1 || true
docker rm $(docker ps --filter "network=$FEDER8_THERAPEUTIC_AREA-studio-net" -q -a) > /dev/null 2>&1 || true

echo "Create $FEDER8_THERAPEUTIC_AREA-net network if it does not exists"
docker network create --driver bridge $FEDER8_THERAPEUTIC_AREA-net > /dev/null 2>&1 || true
echo "Create $FEDER8_THERAPEUTIC_AREA-studio-frontend-net network if it does not exists"
docker network create --driver bridge $FEDER8_THERAPEUTIC_AREA-studio-frontend-net > /dev/null 2>&1 || true
echo "Create $FEDER8_THERAPEUTIC_AREA-studio-net network if it does not exists"
docker network create --driver bridge $FEDER8_THERAPEUTIC_AREA-studio-net > /dev/null 2>&1 || true

echo "Pull $FEDER8_THERAPEUTIC_AREA/$FEDER8_THERAPEUTIC_AREA-studio:$TAG from docker hub. This could take a while if not present on machine"
echo "$FEDER8_CLI_SECRET" | docker login https://$FEDER8_THERAPEUTIC_AREA_URL --username $FEDER8_EMAIL_ADDRESS --password-stdin
docker pull $FEDER8_THERAPEUTIC_AREA_URL/$FEDER8_THERAPEUTIC_AREA/$FEDER8_THERAPEUTIC_AREA-studio:$TAG

echo "Run $FEDER8_THERAPEUTIC_AREA/$FEDER8_THERAPEUTIC_AREA-studio:$TAG container. This could take a while..."
docker run \
--name "$FEDER8_THERAPEUTIC_AREA-studio-chronicle" \
--restart on-failure:5 \
--security-opt no-new-privileges \
--env-file honeur-studio-chronicle.env \
--hostname "cronicle" \
-v "${FEDER8_STUDIO_FOLDER}:/home/${FEDER8_THERAPEUTIC_AREA}studio/__${FEDER8_THERAPEUTIC_AREA_UPPERCASE}Studio__:z" \
-v "r_libraries:/r-libs" \
-v "py_environment:/conda" \
-v "cronicle_data:/opt/cronicle" \
-v "pwsh_modules:/home/${FEDER8_THERAPEUTIC_AREA}studio/.local/share/powershell/Modules" \
-m "500m" \
--cpus "1" \
--pids-limit 100 \
--cpu-shares 1024 \
--ulimit nofile=1024:1024 \
-d \
$FEDER8_THERAPEUTIC_AREA_URL/$FEDER8_THERAPEUTIC_AREA/$FEDER8_THERAPEUTIC_AREA-studio:$TAG cronicle

echo "Connect $FEDER8_THERAPEUTIC_AREA-studio-chronicle to $FEDER8_THERAPEUTIC_AREA-net network"
docker network connect $FEDER8_THERAPEUTIC_AREA-net $FEDER8_THERAPEUTIC_AREA-studio-chronicle > /dev/null 2>&1
echo "Connect $FEDER8_THERAPEUTIC_AREA-studio-chronicle to $FEDER8_THERAPEUTIC_AREA-studio-frontend-net network"
docker network connect $FEDER8_THERAPEUTIC_AREA-studio-frontend-net $FEDER8_THERAPEUTIC_AREA-studio-chronicle > /dev/null 2>&1
echo "Connect $FEDER8_THERAPEUTIC_AREA-studio-chronicle to $FEDER8_THERAPEUTIC_AREA-studio-net network"
docker network connect $FEDER8_THERAPEUTIC_AREA-studio-net $FEDER8_THERAPEUTIC_AREA-studio-chronicle > /dev/null 2>&1


echo "Run $FEDER8_THERAPEUTIC_AREA/$FEDER8_THERAPEUTIC_AREA-studio:$TAG container. This could take a while..."
docker run \
--name "$FEDER8_THERAPEUTIC_AREA-studio" \
--restart on-failure:5 \
--security-opt no-new-privileges \
--env-file honeur-studio.env \
-v "shared:/var/lib/shared:ro" \
-v "$CERTIFICATE_FOLDER/$FEDER8_THERAPEUTIC_AREA-studio:/home/certs" \
-m "1g" \
--cpus "2" \
--pids-limit 100 \
--cpu-shares 1024 \
--ulimit nofile=1024:1024 \
-d \
$FEDER8_THERAPEUTIC_AREA_URL/$FEDER8_THERAPEUTIC_AREA/$FEDER8_THERAPEUTIC_AREA-studio:$TAG shinyproxy


echo Connect $FEDER8_THERAPEUTIC_AREA-studio to $FEDER8_THERAPEUTIC_AREA-net network
docker network connect $FEDER8_THERAPEUTIC_AREA-net $FEDER8_THERAPEUTIC_AREA-studio > /dev/null 2>&1
echo Connect $FEDER8_THERAPEUTIC_AREA-studio to $FEDER8_THERAPEUTIC_AREA-studio-frontend-net network
docker network connect $FEDER8_THERAPEUTIC_AREA-studio-frontend-net $FEDER8_THERAPEUTIC_AREA-studio > /dev/null 2>&1
echo Connect $FEDER8_THERAPEUTIC_AREA-studio to $FEDER8_THERAPEUTIC_AREA-studio-net network
docker network connect $FEDER8_THERAPEUTIC_AREA-studio-net $FEDER8_THERAPEUTIC_AREA-studio > /dev/null 2>&1

echo "Clean up helper files"
rm -rf honeur-studio.env
rm -rf honeur-studio-chronicle.env

echo "Done"