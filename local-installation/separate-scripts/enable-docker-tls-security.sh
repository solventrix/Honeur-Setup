#!/usr/bin/env bash

DOCKER_SERVICE_DIR="/etc/systemd/system/docker.service.d"
DOCKER_HOST_IP=172.17.0.1
DOCKER_HOSTNAME=$HOSTNAME
read -p "Enter / confirm the DNS name or hostname of this server [$HOSTNAME]: " DOCKER_HOSTNAME
DOCKER_HOSTNAME=${DOCKER_HOSTNAME:-$HOSTNAME}

read -p "Enter the folder containing the certificates [$PWD/certificates]: " CERTIFICATE_FOLDER
CERTIFICATE_FOLDER=${CERTIFICATE_FOLDER:-$PWD/certificates}

if [ ! -d "$CERTIFICATE_FOLDER" ]; then
    echo "Warning: '$CERTIFICATE_FOLDER' NOT found.  Abort."
    exit
fi

# Run authorization broker with Docker
unset DOCKER_HOST
unset DOCKER_TLS_VERIFY
# Create policy file
echo "01a. Create policy file"
echo -n "" > $CERTIFICATE_FOLDER/policy.json
echo '{"name":"full-access","users":["", "host"],"actions":[""]}' >> $CERTIFICATE_FOLDER/policy.json
echo '{"name":"feder8-studio","users":["feder8"],"actions":["container_create","container_inspect","container_list","container_logs","container_start","container_delete","docker_auth","docker_version","image_list","image_create","image_inspect","network_connect","network_disconnect","volume_list","volume_create"]}' >> $CERTIFICATE_FOLDER/policy.json
echo "01b. Stop and remove authorization broker container if exists"
docker stop authz-broker > /dev/null 2>&1 || true
docker rm authz-broker > /dev/null 2>&1 || true
echo "01c. Start authorization broker container"
docker run -d  --name "authz-broker" --restart=always -v $CERTIFICATE_FOLDER/policy.json:/var/lib/authz-broker/policy.json -v /run/docker/plugins/:/run/docker/plugins twistlock/authz-broker

if ! command -v systemctl &> /dev/null
then
    echo "Warning: 'systemctl' command NOT found.  TLS security cannot be enabled automatically."
    exit
fi

if [[ ! -d "$DOCKER_SERVICE_DIR" ]] ; then
    sudo mkdir -p $DOCKER_SERVICE_DIR
fi

# Edit Docker service
echo "02. Secure Docker service"
echo -n "" > override.conf
echo "[Service]" >> override.conf
echo "ExecStart=" >> override.conf
echo "ExecStart=/usr/bin/dockerd --tlsverify --tlscacert=$CERTIFICATE_FOLDER/ca.pem --tlscert=$CERTIFICATE_FOLDER/server-cert.pem --tlskey=$CERTIFICATE_FOLDER/server-key.pem -H=0.0.0.0:2376 -H fd:// --containerd=/run/containerd/containerd.sock --authorization-plugin=authz-broker \$OPTIONS \$DOCKER_STORAGE_OPTIONS \$DOCKER_ADD_RUNTIMES" >> override.conf
sudo cp override.conf $DOCKER_SERVICE_DIR"/override.conf"
echo "Restarting Docker..."
sudo systemctl daemon-reload
sudo systemctl restart docker

# Secure Docker client
echo "03. Secure Docker client"
mkdir -pv ~/.docker
rm -rf ~/.docker/*.pem
cp -v $CERTIFICATE_FOLDER/host-client-key.pem ~/.docker/key.pem
cp -v $CERTIFICATE_FOLDER/host-client-cert.pem ~/.docker/cert.pem
cp -v $CERTIFICATE_FOLDER/ca.pem ~/.docker
export DOCKER_HOST_IP=172.17.0.1
export DOCKER_HOST=tcp://$DOCKER_HOSTNAME:2376 DOCKER_TLS_VERIFY=1
#echo "export DOCKER_HOST=tcp://$DOCKER_HOST_IP:2376 DOCKER_TLS_VERIFY=1" >> ~/.bashrc
