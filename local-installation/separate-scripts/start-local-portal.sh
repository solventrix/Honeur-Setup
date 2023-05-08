#!/usr/bin/env bash

TAG=2.0.22
REGISTRY=harbor.honeur.org

if [[ $OSTYPE == 'darwin'* ]]; then
  IS_MAC=true
else
  IS_MAC=false
fi

#if systemctl show --property ActiveState docker &> /dev/null; then
#    DOCKER_CERT_SUPPORT=true
#else
#    DOCKER_CERT_SUPPORT=false
#fi
DOCKER_CERT_SUPPORT=false

docker pull ${REGISTRY}/library/install-script:${TAG}
docker run --rm -it --name feder8-installer -e IS_WINDOWS=false -e IS_MAC=$IS_MAC -e DOCKER_CERT_SUPPORT=$DOCKER_CERT_SUPPORT -v /var/run/docker.sock:/var/run/docker.sock ${REGISTRY}/library/install-script:${TAG} feder8 init local-portal
