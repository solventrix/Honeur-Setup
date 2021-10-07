@ECHO off

SET TAG=2.0.1
SET REGISTRY=harbor-uat.honeur.org

docker pull %REGISTRY%/library/install-script:%TAG%
docker run --rm -it --name feder8-installer -e CURRENT_DIRECTORY=%CD% -e IS_WINDOWS=true -v /var/run/docker.sock:/var/run/docker.sock %REGISTRY%/library/install-script:%TAG% feder8 init zeppelin
