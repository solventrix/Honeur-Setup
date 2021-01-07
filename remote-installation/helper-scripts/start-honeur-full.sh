#!/usr/bin/env bash
set -eu

CURRENT_DIRECTORY=$(pwd)

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
read -p 'Enter your HONEUR organization [Janssen]: ' HONEUR_ANALYTICS_ORGANIZATION
HONEUR_ANALYTICS_ORGANIZATION=${HONEUR_ANALYTICS_ORGANIZATION:-Janssen}
read -p "Enter the directory where HONEUR Studio will store its data [$CURRENT_DIRECTORY/honeurstudio]: " HONEUR_HONEUR_STUDIO_FOLDER
HONEUR_HONEUR_STUDIO_FOLDER=${HONEUR_HONEUR_STUDIO_FOLDER:-$CURRENT_DIRECTORY/honeurstudio}

if [ ! "$HONEUR_SECURITY_METHOD" = "none" ]; then
    read -p "User Management administrator username [admin]: " HONEUR_USERMGMT_ADMIN_USERNAME
    HONEUR_USERMGMT_ADMIN_USERNAME=${HONEUR_USERMGMT_ADMIN_USERNAME:-admin}
    read -p "User Management administrator password [admin]: " HONEUR_USERMGMT_ADMIN_PASSWORD
    HONEUR_USERMGMT_ADMIN_PASSWORD=${HONEUR_USERMGMT_ADMIN_PASSWORD:-admin}
fi

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/remote-installation/start-postgres-honeur.sh --output start-postgres.sh
chmod +x start-postgres.sh
./start-postgres.sh
rm -rf start-postgres.sh

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/remote-installation/start-atlas-webapi.sh --output start-atlas-webapi.sh
chmod +x start-atlas-webapi.sh
{
  echo "$HONEUR_HOST_MACHINE";
  echo "$HONEUR_SECURITY_METHOD";
  [[ "$HONEUR_SECURITY_METHOD" = "ldap" ]] && echo "$HONEUR_SECURITY_LDAP_URL";
  [[ "$HONEUR_SECURITY_METHOD" = "ldap" ]] && echo "$HONEUR_SECURITY_LDAP_SYSTEM_USERNAME";
  [[ "$HONEUR_SECURITY_METHOD" = "ldap" ]] && echo "$HONEUR_SECURITY_LDAP_SYSTEM_PASSWORD";
  [[ "$HONEUR_SECURITY_METHOD" = "ldap" ]] && echo "$HONEUR_SECURITY_LDAP_BASE_DN";
  [[ "$HONEUR_SECURITY_METHOD" = "ldap" ]] && echo "$HONEUR_SECURITY_LDAP_DN"
} | ./start-atlas-webapi.sh
rm -rf start-atlas-webapi.sh

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/remote-installation/start-zeppelin.sh --output start-zeppelin.sh
chmod +x start-zeppelin.sh
{
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

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/remote-installation/start-distributed-analytics.sh --output start-distributed-analytics.sh
chmod +x start-distributed-analytics.sh
{
  echo "$HONEUR_ANALYTICS_SHARED_FOLDER";
  echo "$HONEUR_ANALYTICS_ORGANIZATION"
} | ./start-distributed-analytics.sh

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/remote-installation/start-honeur-studio.sh --output start-honeur-studio.sh
chmod +x start-honeur-studio.sh
{
  echo "$HONEUR_HOST_MACHINE";
  echo "$HONEUR_HONEUR_STUDIO_FOLDER";
  echo "$HONEUR_SECURITY_METHOD";
  [[ "$HONEUR_SECURITY_METHOD" = "ldap" ]] && echo "$HONEUR_SECURITY_LDAP_URL";
  [[ "$HONEUR_SECURITY_METHOD" = "ldap" ]] && echo "$HONEUR_SECURITY_LDAP_SYSTEM_USERNAME";
  [[ "$HONEUR_SECURITY_METHOD" = "ldap" ]] && echo "$HONEUR_SECURITY_LDAP_SYSTEM_PASSWORD";
  [[ "$HONEUR_SECURITY_METHOD" = "ldap" ]] && echo "$HONEUR_SECURITY_LDAP_BASE_DN";
  [[ "$HONEUR_SECURITY_METHOD" = "ldap" ]] && echo "$HONEUR_SECURITY_LDAP_DN"
} | ./start-honeur-studio.sh

if [ ! "$HONEUR_SECURITY_METHOD" = "none" ]; then
    curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/remote-installation/start-user-management.sh --output user-management.sh
    chmod +x start-user-management.sh
    {
        echo "$HONEUR_USERMGMT_ADMIN_USERNAME";
        echo "$HONEUR_USERMGMT_ADMIN_PASSWORD"
    } | ./start-user-management.sh
    rm -rf start-user-management.sh
fi