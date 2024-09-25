@ECHO off

SET TAG=2.1.3
SET REGISTRY=harbor.honeur.org

docker pull %REGISTRY%/library/install-script:%TAG%
docker run --rm -it --name feder8-installer -e CURRENT_DIRECTORY=%CD% -e IS_WINDOWS=true -e IS_MAC=false -e DOCKER_CERT_SUPPORT=false -v /var/run/docker.sock:/var/run/docker.sock %REGISTRY%/library/install-script:%TAG% feder8 init update-custom-concepts
