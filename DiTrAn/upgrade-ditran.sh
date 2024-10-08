#!/usr/bin/env bash

TAG=2.0.30
REGISTRY=harbor.honeur.org

#if systemctl show --property ActiveState docker &> /dev/null; then
#    DOCKER_CERT_SUPPORT=true
#else
#    DOCKER_CERT_SUPPORT=false
#fi

DOCKER_CERT_SUPPORT=false

if [[ $OSTYPE == 'darwin'* ]]; then
  IS_MAC=true
else
  IS_MAC=false
fi

echo "Pull local installation script"
docker pull ${REGISTRY}/library/install-script:${TAG}

echo "Upgrade Feder8 Studio"
docker run --rm -it --name feder8-installer -e CURRENT_DIRECTORY="$(pwd)" -e IS_WINDOWS=false -e IS_MAC=$IS_MAC -e DOCKER_CERT_SUPPORT=$DOCKER_CERT_SUPPORT -v /var/run/docker.sock:/var/run/docker.sock ${REGISTRY}/library/install-script:${TAG} feder8 init feder8-studio -ta honeur

echo "Upgrade DiTrAn"
docker run --rm -it --name feder8-installer -e CURRENT_DIRECTORY="$(pwd)" -e IS_WINDOWS=false -e IS_MAC=$IS_MAC -e DOCKER_CERT_SUPPORT=$DOCKER_CERT_SUPPORT -v /var/run/docker.sock:/var/run/docker.sock ${REGISTRY}/library/install-script:${TAG} feder8 init ditran -ta honeur
