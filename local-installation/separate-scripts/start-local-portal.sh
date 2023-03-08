#!/usr/bin/env bash

TAG=2.0.22
REGISTRY=harbor.honeur.org

if systemctl show --property ActiveState docker &> /dev/null; then
    DOCKER_CERT_SUPPORT=true
else
    DOCKER_CERT_SUPPORT=false
fi

if [[ $OSTYPE == 'darwin'* ]]; then
  IS_MAC=true
else
  IS_MAC=false
fi

BRIDGE_GATEWAY_IP=$(docker network inspect bridge -f "{{ (index .IPAM.Config 0).Gateway }}")

docker pull ${REGISTRY}/library/install-script:${TAG}
docker run --rm -it --name feder8-installer -e DOCKER_CERT_SUPPORT=$DOCKER_CERT_SUPPORT -e IS_MAC=$IS_MAC -e FEDER8_INSTALL_DOCKER_HOST=$BRIDGE_GATEWAY_IP -v /var/run/docker.sock:/var/run/docker.sock ${REGISTRY}/library/install-script:${TAG} feder8 init local-portal
