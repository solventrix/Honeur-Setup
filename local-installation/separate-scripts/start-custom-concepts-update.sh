#!/usr/bin/env bash
TAG=2.1.3
REGISTRY=harbor.honeur.org

docker pull ${REGISTRY}/library/install-script:${TAG}
docker run --rm -it --name feder8-installer -e CURRENT_DIRECTORY=$(pwd) -e IS_WINDOWS=false -e DOCKER_CERT_SUPPORT=false -v /var/run/docker.sock:/var/run/docker.sock ${REGISTRY}/library/install-script:${TAG} feder8 init update-custom-concepts
