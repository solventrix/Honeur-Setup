@ECHO off
SET TAG=2.0.17
SET REGISTRY=harbor-dev.honeur.org

docker pull %REGISTRY%/library/install-script:%TAG%
docker run --rm -it --name feder8-installer -e IS_WINDOWS=true -v /var/run/docker.sock:/var/run/docker.sock %REGISTRY%/library/install-script:%TAG% feder8 init radiant
