#!/usr/bin/env bash
TAG=2.0.17
REGISTRY=harbor-uat.honeur.org

docker pull ${REGISTRY}/library/install-script:${TAG}
docker run --rm -it --name feder8-installer -v /var/run/docker.sock:/var/run/docker.sock ${REGISTRY}/library/install-script:${TAG} feder8 init disease-explorer