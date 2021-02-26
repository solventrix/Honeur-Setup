#!/bin/bash
# Script to protect the Docker daemon socket by use of TLS (HTTPS)
# Peter Moorthamer - 25/Feb/2021

DOCKER_HOST_IP=172.17.0.1
VALIDITY_DAYS=730
CERTIFICATE_FOLDER=certificates

if [ -d "$CERTIFICATE_FOLDER" ]; then
    echo "Info: '$CERTIFICATE_FOLDER' folder already exists."
    read -p "Confirm (y) to clear the folder contents or abort the script (n): " CLEAR_FOLDER
    if [ "$CLEAR_FOLDER" = "y" ]; then
        echo "Clearing folder contents..."
        rm -rfv ./$CERTIFICATE_FOLDER/*
    else
        echo "Script aborted"
        exit
    fi
fi

mkdir -p certificates
cd certificates
  
# 01. Create CA keys 
echo "01a. Create ca-key.pem"
# Generate CA password
LC_CTYPE=C GEN_CA_PWD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
# Allow to override the generated CA password
read -p "Enter password for CA certificate [$GEN_CA_PWD]: " CA_PWD
CA_PWD=${CA_PWD:-$GEN_CA_PWD}
openssl genrsa -aes256 -out ca-key.pem -passout pass:$CA_PWD 4096
echo "01b. Create ca.pem"
openssl req -new -passin pass:$CA_PWD -x509 -days $VALIDITY_DAYS -subj "/C=BE/ST=Antwerp/L=Beerse/O=HONEUR/OU=Data Sciences/CN=$DOCKER_HOST_IP" -key ca-key.pem -sha256 -out ca.pem

# Create server keys 
echo "02a. Create server-key.pem"
openssl genrsa -out server-key.pem 4096
echo "02b. Create server.csr"
openssl req -subj "/CN=$DOCKER_HOST_IP" -sha256 -new -key server-key.pem -out server.csr
echo "02c. Create server-cert.pem"
echo -n "" > extfile.cnf
echo subjectAltName = DNS:$DOCKER_HOST_IP,IP:$DOCKER_HOST_IP,IP:127.0.0.1 >> extfile.cnf
echo extendedKeyUsage = serverAuth >> extfile.cnf
openssl x509 -req -passin pass:$CA_PWD -days $VALIDITY_DAYS -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem -extfile extfile.cnf

# Create host client keys
echo "03a. Create host-client-key.pem"
openssl genrsa -out host-client-key.pem 4096
echo "03b. Create host-client.csr"
openssl req -passin pass:$CA_PWD -subj '/CN=host' -new -key host-client-key.pem -out host-client.csr
echo -n "" > extfile-host-client.cnf
echo extendedKeyUsage = clientAuth > extfile-host-client.cnf
echo "03c. Create host-client-cert.pem"
openssl x509 -req -passin pass:$CA_PWD -days $VALIDITY_DAYS -sha256 -in host-client.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out host-client-cert.pem -extfile extfile-host-client.cnf

# Create honeur-studio client keys
echo "04a. Create honeur-studio-client-key.pem"
openssl genrsa -out honeur-studio-client-key.pem 4096
echo "04b. Create honeur-studio-client.csr"
openssl req -passin pass:$CA_PWD -subj '/CN=honeur-studio' -new -key honeur-studio-client-key.pem -out honeur-studio-client.csr
echo -n "" > extfile-honeur-studio-client.cnf
echo extendedKeyUsage = clientAuth > extfile-honeur-studio-client.cnf
echo "04c. Create honeur-studio-client-cert.pem"
openssl x509 -req -passin pass:$CA_PWD -days $VALIDITY_DAYS -sha256 -in honeur-studio-client.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out honeur-studio-client-cert.pem -extfile extfile-honeur-studio-client.cnf

# Set minimal permissions
echo "05. Limit access to keys and certificates"
chmod -v 0400 ca-key.pem server-key.pem host-client-key.pem
chmod -v 0444 ca.pem server-cert.pem host-client-cert.pem

# Cleanup
echo "06. Cleanup"
rm -v server.csr host-client.csr honeur-studio-client.csr extfile.cnf extfile-host-client.cnf extfile-honeur-studio-client.cnf 
unset GEN_CA_PWD
unset CA_PWD
