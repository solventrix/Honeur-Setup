#!/usr/bin/env bash
set -eu

CURRENT_DIRECTORY=$(pwd)

FEDER8_THERAPEUTIC_AREA=phederation
FEDER8_THERAPEUTIC_AREA_DOMAIN=phederation.org

read -p "Enter email address used to login to https://portal-uat.$FEDER8_THERAPEUTIC_AREA_DOMAIN: " FEDER8_EMAIL_ADDRESS
while [[ "$FEDER8_EMAIL_ADDRESS" == "" ]]; do
    echo "Email address can not be empty"
    read -p "Enter email address used to login to https://portal-uat.$FEDER8_THERAPEUTIC_AREA_DOMAIN: " FEDER8_EMAIL_ADDRESS
done
echo "Surf to https://$FEDER8_THERAPEUTIC_AREA_URL and login using the button \"LOGIN VIA OIDC PROVIDER\". Then click your account name on the top right corner of the screen and click \"User Profile\". Copy the CLI secret by clicking the copy symbol next to the text field."
read -p 'Enter the CLI Secret: ' FEDER8_CLI_SECRET
while [[ "$FEDER8_CLI_SECRET" == "" ]]; do
    echo "CLI Secret can not be empty"
    read -p "Enter the CLI Secret: " FEDER8_CLI_SECRET
done

read -p "Use JDBC users or LDAP or No authentication? Enter jdbc/ldap/none. [none]: " HONEUR_SECURITY_METHOD
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
    HONEUR_SECURITY_LDAP_DN=${HONEUR_SECURITY_LDAP_DN:-uid=\{0\},dc=example,dc=com}
elif [ "$HONEUR_SECURITY_METHOD" = "jdbc" ]; then
    HONEUR_SECURITY_LDAP_URL=ldap://localhost:389
    HONEUR_SECURITY_LDAP_SYSTEM_USERNAME=username
    HONEUR_SECURITY_LDAP_SYSTEM_PASSWORD=password
    HONEUR_SECURITY_LDAP_BASE_DN=dc=example,dc=org
    HONEUR_SECURITY_LDAP_DN=cn={0},dc=example,dc=org
fi

read -p 'Enter the FQDN(Fully Qualified Domain Name eg. www.example.com) or public IP address(eg. 125.24.44.18) of the host machine. Use localhost to for testing [localhost]: ' HONEUR_HOST_MACHINE
HONEUR_HOST_MACHINE=${HONEUR_HOST_MACHINE:-localhost}
read -p "Enter the directory where the zeppelin logs will kept on the host machine [$CURRENT_DIRECTORY/zeppelin/logs]: " HONEUR_ZEPPELIN_LOGS
HONEUR_ZEPPELIN_LOGS=${HONEUR_ZEPPELIN_LOGS:-$CURRENT_DIRECTORY/zeppelin/logs}
read -p "Enter the directory where the zeppelin notebooks will kept on the host machine [$CURRENT_DIRECTORY/zeppelin/notebook]: " HONEUR_ZEPPELIN_NOTEBOOKS
HONEUR_ZEPPELIN_NOTEBOOKS=${HONEUR_ZEPPELIN_NOTEBOOKS:-$CURRENT_DIRECTORY/zeppelin/notebook}
read -p "Enter the directory where Zeppelin will save the prepared distributed analytics data [$CURRENT_DIRECTORY/distributed-analytics]: " HONEUR_ANALYTICS_SHARED_FOLDER
HONEUR_ANALYTICS_SHARED_FOLDER=${HONEUR_ANALYTICS_SHARED_FOLDER:-$CURRENT_DIRECTORY/distributed-analytics}

if [ ! "$HONEUR_SECURITY_METHOD" = "none" ]; then
    read -p "User Management administrator username [admin]: " HONEUR_USERMGMT_ADMIN_USERNAME
    HONEUR_USERMGMT_ADMIN_USERNAME=${HONEUR_USERMGMT_ADMIN_USERNAME:-admin}
    read -p "User Management administrator password [admin]: " HONEUR_USERMGMT_ADMIN_PASSWORD
    HONEUR_USERMGMT_ADMIN_PASSWORD=${HONEUR_USERMGMT_ADMIN_PASSWORD:-admin}
fi

HONEUR_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
HONEUR_ADMIN_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)

read -p "Enter password for $FEDER8_THERAPEUTIC_AREA database user [$HONEUR_PASSWORD]: " HONEUR_PASSWORD
read -p "Enter password for $FEDER8_THERAPEUTIC_AREA admin database user [$HONEUR_ADMIN_PASSWORD]: " HONEUR_ADMIN_PASSWORD

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/remote-installation/separate-scripts/start-postgres.sh --output start-postgres.sh
chmod +x start-postgres.sh
{
  echo "$FEDER8_THERAPEUTIC_AREA";
  echo "$FEDER8_EMAIL_ADDRESS";
  echo "$FEDER8_CLI_SECRET";
  echo "$HONEUR_PASSWORD";
  echo "$HONEUR_ADMIN_PASSWORD"
} | ./start-postgres.sh
rm -rf start-postgres.sh

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/remote-installation/separate-scripts/start-atlas-webapi.sh --output start-atlas-webapi.sh
chmod +x start-atlas-webapi.sh
{
  echo "$FEDER8_THERAPEUTIC_AREA";
  echo "$FEDER8_EMAIL_ADDRESS";
  echo "$FEDER8_CLI_SECRET";
  echo "$HONEUR_HOST_MACHINE";
  echo "$HONEUR_SECURITY_METHOD";
  [[ "$HONEUR_SECURITY_METHOD" = "ldap" ]] && echo "$HONEUR_SECURITY_LDAP_URL";
  [[ "$HONEUR_SECURITY_METHOD" = "ldap" ]] && echo "$HONEUR_SECURITY_LDAP_SYSTEM_USERNAME";
  [[ "$HONEUR_SECURITY_METHOD" = "ldap" ]] && echo "$HONEUR_SECURITY_LDAP_SYSTEM_PASSWORD";
  [[ "$HONEUR_SECURITY_METHOD" = "ldap" ]] && echo "$HONEUR_SECURITY_LDAP_BASE_DN";
  [[ "$HONEUR_SECURITY_METHOD" = "ldap" ]] && echo "$HONEUR_SECURITY_LDAP_DN"
} | ./start-atlas-webapi.sh
rm -rf start-atlas-webapi.sh

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/remote-installation/separate-scripts/start-zeppelin.sh --output start-zeppelin.sh
chmod +x start-zeppelin.sh
{
  echo "$FEDER8_THERAPEUTIC_AREA";
  echo "$FEDER8_EMAIL_ADDRESS";
  echo "$FEDER8_CLI_SECRET";
  echo "$HONEUR_ZEPPELIN_LOGS";
  echo "$HONEUR_ZEPPELIN_NOTEBOOKS";
  echo "$HONEUR_ANALYTICS_SHARED_FOLDER";
  echo "$HONEUR_SECURITY_METHOD";
  [[ "$HONEUR_SECURITY_METHOD" = "ldap" ]] && echo "$HONEUR_SECURITY_LDAP_URL";
  [[ "$HONEUR_SECURITY_METHOD" = "ldap" ]] && echo "$HONEUR_SECURITY_LDAP_SYSTEM_USERNAME";
  [[ "$HONEUR_SECURITY_METHOD" = "ldap" ]] && echo "$HONEUR_SECURITY_LDAP_SYSTEM_PASSWORD";
  [[ "$HONEUR_SECURITY_METHOD" = "ldap" ]] && echo "$HONEUR_SECURITY_LDAP_BASE_DN";
  [[ "$HONEUR_SECURITY_METHOD" = "ldap" ]] && echo "$HONEUR_SECURITY_LDAP_DN"
} | ./start-zeppelin.sh
rm -rf start-zeppelin.sh

if [ ! "$HONEUR_SECURITY_METHOD" = "none" ]; then
    curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/remote-installation/separate-scripts/start-user-management.sh --output start-user-management.sh
    chmod +x start-user-management.sh
    {
      echo "$FEDER8_THERAPEUTIC_AREA";
      echo "$FEDER8_EMAIL_ADDRESS";
      echo "$FEDER8_CLI_SECRET";
      echo "$HONEUR_USERMGMT_ADMIN_USERNAME";
      echo "$HONEUR_USERMGMT_ADMIN_PASSWORD"
    } | ./start-user-management.sh
    rm -rf start-user-management.sh
fi

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/remote-installation/separate-scripts/start-nginx.sh --output start-nginx.sh
chmod +x start-nginx.sh
{
  echo "$FEDER8_THERAPEUTIC_AREA";
  echo "$FEDER8_EMAIL_ADDRESS";
  echo "$FEDER8_CLI_SECRET";
} | ./start-nginx.sh
rm -rf start-nginx.sh

echo "postgresql is available on $HONEUR_HOST_MACHINE:5444"
echo "Atlas/WebAPI is available on http://$HONEUR_HOST_MACHINE/atlas and http://$HONEUR_HOST_MACHINE/webapi respectively"
echo "Zeppelin is available on http://$HONEUR_HOST_MACHINE/zeppelin"
echo "Zeppelin logs are available in directory $HONEUR_ZEPPELIN_LOGS"
echo "Zeppelin notebooks are available in directory $HONEUR_ZEPPELIN_NOTEBOOKS"
[ ! "$HONEUR_SECURITY_METHOD" = "none" ] && echo "User Management is available on http://$HONEUR_HOST_MACHINE/user-mgmt"
