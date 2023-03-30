#!/bin/bash
# Script to protect the Docker daemon socket by use of TLS (HTTPS)
# Peter Moorthamer - 25/Feb/2021

DOCKER_HOSTNAME=$HOSTNAME
read -p "Enter / confirm the DNS name or hostname of this server [$HOSTNAME]: " DOCKER_HOSTNAME
DOCKER_HOSTNAME=${DOCKER_HOSTNAME:-$HOSTNAME}

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
openssl req -new -passin pass:$CA_PWD -x509 -days $VALIDITY_DAYS -subj "/C=BE/ST=Antwerp/L=Beerse/O=FEDER8/OU=Data Sciences/CN=$DOCKER_HOSTNAME" -key ca-key.pem -sha256 -out ca.pem

# Create server keys
echo "02a. Create server-key.pem"
openssl genrsa -out server-key.pem 4096
echo "02b. Create server.csr"
openssl req -subj "/CN=$DOCKER_HOSTNAME" -sha256 -new -key server-key.pem -out server.csr
echo "02c. Create server-cert.pem"
echo -n "" > extfile.cnf
echo subjectAltName = DNS:$DOCKER_HOSTNAME,IP:127.0.0.1,IP:172.17.0.1 >> extfile.cnf
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

# Create feder8 client keys
echo "04a. Create feder8-client-key.pem"
openssl genrsa -out feder8-client-key.pem 4096
echo "04b. Create feder8-client.csr"
openssl req -passin pass:$CA_PWD -subj '/CN=feder8' -new -key feder8-client-key.pem -out feder8-client.csr
echo -n "" > extfile-feder8-client.cnf
echo extendedKeyUsage = clientAuth > extfile-feder8-client.cnf
echo "04c. Create feder8-client-cert.pem"
openssl x509 -req -passin pass:$CA_PWD -days $VALIDITY_DAYS -sha256 -in feder8-client.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out feder8-client-cert.pem -extfile extfile-feder8-client.cnf

# Set minimal permissions
echo "05. Limit access to keys and certificates"
chmod -v 0400 ca-key.pem server-key.pem host-client-key.pem
chmod -v 0444 ca.pem server-cert.pem host-client-cert.pem

# Cleanup
echo "06. Cleanup"
rm -v server.csr host-client.csr feder8-client.csr extfile.cnf extfile-host-client.cnf extfile-feder8-client.cnf
unset GEN_CA_PWD
unset CA_PWD

mkdir -p feder8-client-certificates
mv feder8-client-key.pem feder8-client-certificates/key.pem
mv feder8-client-cert.pem feder8-client-certificates/cert.pem
cp -v ca.pem feder8-client-certificates/ca.pem
chmod +r feder8-client-certificates/key.pem
#echo "Change ownership of feder8-client-certificates/key.pem (sudo password required)"
#sudo chown 54321:54321 feder8-client-certificates/key.pem
echo "Feder8 certificates can be found in $(pwd)/feder8-client-certificates"
