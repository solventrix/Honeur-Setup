#!/usr/bin/env bash

TAG=2.0.19
REGISTRY=harbor-uat.honeur.org

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

if [ -f "images.tar" ]; then
  echo Loading docker images. This could take a while...
  docker load < images.tar
  docker run --rm -it --name feder8-installer -e CURRENT_DIRECTORY=$(pwd) -e IS_WINDOWS=false -e IS_MAC=$IS_MAC -e DOCKER_CERT_SUPPORT=$DOCKER_CERT_SUPPORT -v /var/run/docker.sock:/var/run/docker.sock ${REGISTRY}/library/install-script:${TAG} feder8 init full --offline
else
  echo Could not find 'images.tar' in the current directory. Unable to continue.
  exit 1
fi