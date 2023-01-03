#!/usr/bin/env bash

TAG=2.0.21

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

docker run --rm -it --name feder8-installer -e CURRENT_DIRECTORY=${PWD} -e IS_WINDOWS=false -e IS_MAC=$IS_MAC -e DOCKER_CERT_SUPPORT=$DOCKER_CERT_SUPPORT -v /var/run/docker.sock:/var/run/docker.sock feder8/install-script:${TAG} feder8 init full

#docker run --rm -it --name feder8-installer -e CURRENT_DIRECTORY=${PWD} -e IS_WINDOWS=false -e IS_MAC=$IS_MAC -e DOCKER_CERT_SUPPORT=$DOCKER_CERT_SUPPORT -v /var/run/docker.sock:/var/run/docker.sock feder8/install-script:${TAG} feder8 init task-manager
