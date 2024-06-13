#!/usr/bin/env bash
TAG=2.0.23
REGISTRY=harbor.honeur.org

if [[ $OSTYPE == 'darwin'* ]]; then
  IS_MAC=true
else
  IS_MAC=false
fi

if systemctl show --property ActiveState docker &> /dev/null; then
    DOCKER_CERT_SUPPORT=true
else
    DOCKER_CERT_SUPPORT=false
fi

echo "Pull latest local installation script"
docker pull ${REGISTRY}/library/install-script:${TAG}
echo "Upgrade local portal"
docker run --rm -it --name feder8-installer -e IS_WINDOWS=false -e IS_MAC=$IS_MAC -e DOCKER_CERT_SUPPORT=$DOCKER_CERT_SUPPORT -v /var/run/docker.sock:/var/run/docker.sock ${REGISTRY}/library/install-script:${TAG} feder8 init local-portal
echo "Upgrade NGINX"
docker run --rm -it --name feder8-installer -e CURRENT_DIRECTORY=${PWD} -e FEDER8_HOST_HTTP_PORT=8080 -e FEDER8_HOST_HTTPS_PORT=8443 -v /var/run/docker.sock:/var/run/docker.sock ${REGISTRY}/library/install-script:${TAG} feder8 init nginx