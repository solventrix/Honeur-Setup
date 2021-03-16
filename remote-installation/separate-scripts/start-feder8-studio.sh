#!/usr/bin/env bash
set -e

VERSION=2.0.3
TAG=$VERSION
CURRENT_DIRECTORY=$(pwd)

if command -v systemctl &> /dev/null
then
    LINUX=true
else
    LINUX=false
fi

read -p "Enter the Therapeutic Area of choice. Enter honeur/phederation/esfurn/athena [honeur]: " HONEUR_THERAPEUTIC_AREA
while [[ "$HONEUR_THERAPEUTIC_AREA" != "honeur" && "$HONEUR_THERAPEUTIC_AREA" != "phederation" && "$HONEUR_THERAPEUTIC_AREA" != "esfurn" && "$HONEUR_THERAPEUTIC_AREA" != "athena" && "$HONEUR_THERAPEUTIC_AREA" != "" ]]; do
    echo "Enter \"honeur\", \"phederation\", \"esfurn\", \"athena\" or empty for default \"honeur\" value"
    read -p "Enter the Therapeutic Area of choice. Enter honeur/phederation/esfurn/athena [honeur]: " HONEUR_THERAPEUTIC_AREA
done
HONEUR_THERAPEUTIC_AREA=${HONEUR_THERAPEUTIC_AREA:-honeur}
FEDER8_THERAPEUTIC_AREA_UPPERCASE=$(echo "$HONEUR_THERAPEUTIC_AREA" |  tr '[:lower:]' '[:upper:]' )

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

if $LINUX; then
    read -p "Enter the folder containing the certificates [$CURRENT_DIRECTORY/certificates]: " CERTIFICATE_FOLDER
    CERTIFICATE_FOLDER=${CERTIFICATE_FOLDER:-$CURRENT_DIRECTORY/certificates}
    if [ -d "$CERTIFICATE_FOLDER" ]; then
        mkdir -p $CERTIFICATE_FOLDER/$HONEUR_THERAPEUTIC_AREA-studio
        rm -rf $CERTIFICATE_FOLDER/$HONEUR_THERAPEUTIC_AREA-studio/*
        if [ -f "$CERTIFICATE_FOLDER/$HONEUR_THERAPEUTIC_AREA-studio-client-key.pem" ]; then
            cp -v $CERTIFICATE_FOLDER/$HONEUR_THERAPEUTIC_AREA-studio-client-key.pem $CERTIFICATE_FOLDER/$HONEUR_THERAPEUTIC_AREA-studio/key.pem
            cp -v $CERTIFICATE_FOLDER/$HONEUR_THERAPEUTIC_AREA-studio-client-cert.pem $CERTIFICATE_FOLDER/$HONEUR_THERAPEUTIC_AREA-studio/cert.pem
            cp -v $CERTIFICATE_FOLDER/ca.pem $CERTIFICATE_FOLDER/$HONEUR_THERAPEUTIC_AREA-studio/ca.pem
            chmod -v 0400 $CERTIFICATE_FOLDER/$HONEUR_THERAPEUTIC_AREA-studio/key.pem
            chmod -v 0444 $CERTIFICATE_FOLDER/$HONEUR_THERAPEUTIC_AREA-studio/cert.pem
        elif [ -f "$CERTIFICATE_FOLDER/key.pem" ]; then
            cp -v $CERTIFICATE_FOLDER/key.pem $CERTIFICATE_FOLDER/$HONEUR_THERAPEUTIC_AREA-studio/key.pem
            cp -v $CERTIFICATE_FOLDER/cert.pem $CERTIFICATE_FOLDER/$HONEUR_THERAPEUTIC_AREA-studio/cert.pem
            cp -v $CERTIFICATE_FOLDER/ca.pem $CERTIFICATE_FOLDER/$HONEUR_THERAPEUTIC_AREA-studio/ca.pem
        else
            echo "Warning: '$CERTIFICATE_FOLDER' doesn't contain a client certificate for ${HONEUR_THERAPEUTIC_AREA_UPPERCASE} Studio.  Abort."
            exit
        fi
    else
        echo "Warning: '$CERTIFICATE_FOLDER' NOT found.  Abort."
        exit
    fi
fi

read -p 'Enter the FQDN(Fully Qualified Domain Name eg. www.example.com) or public IP address(eg. 125.24.44.18) of the host machine. Use localhost to for testing [localhost]: ' HONEUR_HOST_MACHINE
HONEUR_HOST_MACHINE=${HONEUR_HOST_MACHINE:-localhost}

read -p "Enter the directory where ${HONEUR_THERAPEUTIC_AREA_UPPERCASE} Studio will store its data [$CURRENT_DIRECTORY/${HONEUR_THERAPEUTIC_AREA}studio]: " HONEUR_HONEUR_STUDIO_FOLDER
HONEUR_HONEUR_STUDIO_FOLDER=${HONEUR_HONEUR_STUDIO_FOLDER:-$CURRENT_DIRECTORY/${HONEUR_THERAPEUTIC_AREA}studio}

read -p "Enter the directory where ${HONEUR_THERAPEUTIC_AREA_UPPERCASE} Studio will save the prepared distributed analytics data [$CURRENT_DIRECTORY/distributed-analytics]: " HONEUR_ANALYTICS_SHARED_FOLDER
HONEUR_ANALYTICS_SHARED_FOLDER=${HONEUR_ANALYTICS_SHARED_FOLDER:-$CURRENT_DIRECTORY/distributed-analytics}

read -p "Use jdbc users or LDAP or No for authentication? Enter jdbc/ldap/none. [none]: " HONEUR_SECURITY_METHOD
while [[ "$HONEUR_SECURITY_METHOD" != "none" && "$HONEUR_SECURITY_METHOD" != "ldap" && "$HONEUR_SECURITY_METHOD" != "jdbc" && "$HONEUR_SECURITY_METHOD" != "" ]]; do
    echo "enter \"none\", \"jdbc\", \"ldap\" or empty for default \"none\" value"
    read -p "Use JDBC users, LDAP or No authentication? Enter none/jdbc/ldap. [none]: " HONEUR_SECURITY_METHOD
done
HONEUR_SECURITY_METHOD=${HONEUR_SECURITY_METHOD:-none}

if [ "$HONEUR_SECURITY_METHOD" = "ldap" ]; then
    read -p "security.ldap.url [ldap://ldap.forumsys.com:389]: " HONEUR_SECURITY_LDAP_URL
    HONEUR_SECURITY_LDAP_URL=${HONEUR_SECURITY_LDAP_URL:-ldap://ldap.forumsys.com:389}
    read -p "security.ldap.system.username [cn=read-only-admin,dc=example,dc=com]: " HONEUR_SECURITY_LDAP_SYSTEM_USERNAME
    HONEUR_SECURITY_LDAP_SYSTEM_USERNAME=${HONEUR_SECURITY_LDAP_SYSTEM_USERNAME:-cn=read-only-admin,dc=example,dc=com}
    read -p "security.ldap.system.password [password]: " HONEUR_SECURITY_LDAP_SYSTEM_PASSWORD
    HONEUR_SECURITY_LDAP_SYSTEM_PASSWORD=${HONEUR_SECURITY_LDAP_SYSTEM_PASSWORD:-password}
    read -p "security.ldap.baseDn [dc=example,dc=com]: " HONEUR_SECURITY_LDAP_BASE_DN
    HONEUR_SECURITY_LDAP_BASE_DN=${HONEUR_SECURITY_LDAP_BASE_DN:-dc=example,dc=com}
    read -p "security.ldap.dn [uid={0},dc=example,dc=com]: " HONEUR_SECURITY_LDAP_DN
    HONEUR_SECURITY_LDAP_DN=${honeur_security_ldap_dn:-uid=\{0\},dc=example,dc=com}
fi

USERID=1000

touch honeur-studio.env

echo "TAG=$TAG" > honeur-studio.env
echo "APPLICATION_LOGS_TO_STDOUT=false" >> honeur-studio.env
echo "SITE_NAME=${HONEUR_THERAPEUTIC_AREA}studio" >> honeur-studio.env
echo "CONTENT_PATH=$HONEUR_HONEUR_STUDIO_FOLDER" >> honeur-studio.env
echo "USERID=$USERID" >> honeur-studio.env
echo "DOMAIN_NAME=$HONEUR_HOST_MACHINE" >> honeur-studio.env
echo "HONEUR_DISTRIBUTED_ANALYTICS_DATA_FOLDER=$HONEUR_ANALYTICS_SHARED_FOLDER" >> honeur-studio.env
echo "AUTHENTICATION_METHOD=$HONEUR_SECURITY_METHOD" >> honeur-studio.env
echo "HONEUR_THERAPEUTIC_AREA=$HONEUR_THERAPEUTIC_AREA" >> honeur-studio.env
echo "HONEUR_THERAPEUTIC_AREA_URL=${HONEUR_THERAPEUTIC_AREA_URL}" >> honeur-studio.env
echo "HONEUR_THERAPEUTIC_AREA_UPPERCASE=${HONEUR_THERAPEUTIC_AREA_UPPERCASE}" >> honeur-studio.env
if $LINUX; then
    echo "PROXY_DOCKER_URL=https://172.17.0.1:2376" >> honeur-studio.env
    echo "PROXY_DOCKER_CERT_PATH=/home/certs" >> honeur-studio.env
fi

if [ "$HONEUR_SECURITY_METHOD" = "jdbc" ]; then
    #JDBC
    echo "DATASOURCE_DRIVER_CLASS_NAME=org.postgresql.Driver" >> honeur-studio.env
    echo "DATASOURCE_URL=jdbc:postgresql://postgres:5432/OHDSI?currentSchema=webapi" >> honeur-studio.env
    echo "WEBAPI_ADMIN_USERNAME=ohdsi_admin_user" >> honeur-studio.env
elif [ "$HONEUR_SECURITY_METHOD" = "ldap" ]; then
    #LDAP
    echo "HONEUR_STUDIO_LDAP_URL=$HONEUR_SECURITY_LDAP_URL/$HONEUR_SECURITY_LDAP_BASE_DN" >> honeur-studio.env
    echo "HONEUR_STUDIO_LDAP_DN=uid={0}" >> honeur-studio.env
    echo "HONEUR_STUDIO_LDAP_MANAGER_DN=$HONEUR_SECURITY_LDAP_SYSTEM_USERNAME" >> honeur-studio.env
    echo "HONEUR_STUDIO_LDAP_MANAGER_PASSWORD=$HONEUR_SECURITY_LDAP_SYSTEM_PASSWORD" >> honeur-studio.env
fi

echo "SITE_NAME=$HONEUR_THERAPEUTIC_AREAstudio" > honeur-studio-chronicle.env
echo "USERID=$USERID" >> honeur-studio-chronicle.env
echo "USER=$HONEUR_THERAPEUTIC_AREAstudio" >> honeur-studio-chronicle.env

echo "Stop and remove all $HONEUR_THERAPEUTIC_AREA-studio containers if exists"
docker stop $(docker ps --filter "network=$HONEUR_THERAPEUTIC_AREA-studio-net" -q -a) > /dev/null 2>&1 || true
docker rm $(docker ps --filter "network=$HONEUR_THERAPEUTIC_AREA-studio-net" -q -a) > /dev/null 2>&1 || true

echo "Create $HONEUR_THERAPEUTIC_AREA-net network if it does not exists"
docker network create --driver bridge $HONEUR_THERAPEUTIC_AREA-net > /dev/null 2>&1 || true
echo "Create $HONEUR_THERAPEUTIC_AREA-studio-frontend-net network if it does not exists"
docker network create --driver bridge $HONEUR_THERAPEUTIC_AREA-studio-frontend-net > /dev/null 2>&1 || true
echo "Create $HONEUR_THERAPEUTIC_AREA-studio-net network if it does not exists"
docker network create --driver bridge $HONEUR_THERAPEUTIC_AREA-studio-net > /dev/null 2>&1 || true

echo "Pull $HONEUR_THERAPEUTIC_AREA/$HONEUR_THERAPEUTIC_AREA-studio:$TAG from docker hub. This could take a while if not present on machine"
echo "$HONEUR_CLI_SECRET" | docker login https://$HONEUR_THERAPEUTIC_AREA_URL --username $HONEUR_EMAIL_ADDRESS --password-stdin
docker pull $HONEUR_THERAPEUTIC_AREA_URL/$HONEUR_THERAPEUTIC_AREA/$HONEUR_THERAPEUTIC_AREA-studio:$TAG

echo "Run $HONEUR_THERAPEUTIC_AREA/$HONEUR_THERAPEUTIC_AREA-studio:$TAG container. This could take a while..."
docker run \
--name "$HONEUR_THERAPEUTIC_AREA-studio-chronicle" \
--restart on-failure:5 \
--security-opt no-new-privileges \
--env-file honeur-studio-chronicle.env \
--hostname "cronicle" \
-v "${HONEUR_HONEUR_STUDIO_FOLDER}:/home/${HONEUR_THERAPEUTIC_AREA}studio/__${HONEUR_THERAPEUTIC_AREA_UPPERCASE}Studio__:z" \
-v "r_libraries:/r-libs" \
-v "py_environment:/conda" \
-v "cronicle_data:/opt/cronicle" \
-v "pwsh_modules:/home/${HONEUR_THERAPEUTIC_AREA}studio/.local/share/powershell/Modules" \
-m "500m" \
--cpus "1" \
--pids-limit 100 \
--cpu-shares 1024 \
--ulimit nofile=1024:1024 \
-d \
$HONEUR_THERAPEUTIC_AREA_URL/$HONEUR_THERAPEUTIC_AREA/$HONEUR_THERAPEUTIC_AREA-studio:$TAG cronicle

echo "Connect $HONEUR_THERAPEUTIC_AREA-studio-chronicle to $HONEUR_THERAPEUTIC_AREA-net network"
docker network connect $HONEUR_THERAPEUTIC_AREA-net $HONEUR_THERAPEUTIC_AREA-studio-chronicle > /dev/null 2>&1
echo "Connect $HONEUR_THERAPEUTIC_AREA-studio-chronicle to $HONEUR_THERAPEUTIC_AREA-studio-frontend-net network"
docker network connect $HONEUR_THERAPEUTIC_AREA-studio-frontend-net $HONEUR_THERAPEUTIC_AREA-studio-chronicle > /dev/null 2>&1
echo "Connect $HONEUR_THERAPEUTIC_AREA-studio-chronicle to $HONEUR_THERAPEUTIC_AREA-studio-net network"
docker network connect $HONEUR_THERAPEUTIC_AREA-studio-net $HONEUR_THERAPEUTIC_AREA-studio-chronicle > /dev/null 2>&1


echo "Run $HONEUR_THERAPEUTIC_AREA/$HONEUR_THERAPEUTIC_AREA-studio:$TAG container. This could take a while..."
if $LINUX; then
  docker run \
  --name "$HONEUR_THERAPEUTIC_AREA-studio" \
  --restart on-failure:5 \
  --security-opt no-new-privileges \
  --env-file honeur-studio.env \
  -v "shared:/var/lib/shared:ro" \
  -v "$CERTIFICATE_FOLDER/honeur-studio:/home/certs" \
  -m "1g" \
  --cpus "2" \
  --pids-limit 100 \
  --cpu-shares 1024 \
  --ulimit nofile=1024:1024 \
  -d \
  $HONEUR_THERAPEUTIC_AREA_URL/$HONEUR_THERAPEUTIC_AREA/$HONEUR_THERAPEUTIC_AREA-studio:$TAG shinyproxy
else
  docker run \
  --name "$HONEUR_THERAPEUTIC_AREA-studio" \
  --restart on-failure:5 \
  --security-opt no-new-privileges \
  --env-file honeur-studio.env \
  -v "shared:/var/lib/shared:ro" \
  -v "/var/run/docker.sock:/var/run/docker.sock" \
  -m "1g" \
  --cpus "2" \
  --pids-limit 100 \
  --cpu-shares 1024 \
  --ulimit nofile=1024:1024 \
  -d \
  $HONEUR_THERAPEUTIC_AREA_URL/$HONEUR_THERAPEUTIC_AREA/$HONEUR_THERAPEUTIC_AREA-studio:$TAG shinyproxy
fi

echo Connect $HONEUR_THERAPEUTIC_AREA-studio to $HONEUR_THERAPEUTIC_AREA-net network
docker network connect $HONEUR_THERAPEUTIC_AREA-net $HONEUR_THERAPEUTIC_AREA-studio > /dev/null 2>&1
echo Connect $HONEUR_THERAPEUTIC_AREA-studio to $HONEUR_THERAPEUTIC_AREA-studio-frontend-net network
docker network connect $HONEUR_THERAPEUTIC_AREA-studio-frontend-net $HONEUR_THERAPEUTIC_AREA-studio > /dev/null 2>&1
echo Connect $HONEUR_THERAPEUTIC_AREA-studio to $HONEUR_THERAPEUTIC_AREA-studio-net network
docker network connect $HONEUR_THERAPEUTIC_AREA-studio-net $HONEUR_THERAPEUTIC_AREA-studio > /dev/null 2>&1

echo "Clean up helper files"
rm -rf honeur-studio.env
rm -rf honeur-studio-chronicle.env

echo "Done"