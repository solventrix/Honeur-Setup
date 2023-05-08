#!/usr/bin/env bash

read -p "Enter the folder containing the certificates [$PWD/certificates]: " CERTIFICATE_FOLDER
CERTIFICATE_FOLDER=${CERTIFICATE_FOLDER:-$PWD/certificates}

if [ ! -d "$CERTIFICATE_FOLDER" ]; then
    echo "Warning: '$CERTIFICATE_FOLDER' NOT found.  Abort."
    exit
fi

# Create policy file
echo "Update policy file"
echo -n "" > $CERTIFICATE_FOLDER/policy.json
echo '{"name":"full-access","users":["", "host"],"actions":[""]}' >> $CERTIFICATE_FOLDER/policy.json
echo '{"name":"feder8-studio","users":["feder8"],"actions":["container_create","container_inspect","container_list","container_logs","container_start","container_delete","docker_auth","docker_version","image_list","image_create","image_inspect","network_connect","network_disconnect","volume_list","volume_create"]}' >> $CERTIFICATE_FOLDER/policy.json
