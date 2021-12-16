TAG=2.0.11
REGISTRY=harbor.honeur.org

docker pull ${REGISTRY}/library/install-script:${TAG}
docker run --rm -it --name feder8-installer -e CURRENT_DIRECTORY=$(pwd) -e IS_WINDOWS=false -v /var/run/docker.sock:/var/run/docker.sock ${REGISTRY}/library/install-script:${TAG} feder8 init zeppelin
