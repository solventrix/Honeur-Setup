@ECHO off

SET TAG=2.0.22
SET REGISTRY=harbor.honeur.org

docker logout %REGISTRY%

if exist images.tar (
    echo Loading docker images. This could take a while...
    docker load -i images.tar
    docker run --rm -it --name feder8-installer -e CURRENT_DIRECTORY=%CD% -e IS_WINDOWS=true -e DOCKER_CERT_SUPPORT=false -v /var/run/docker.sock:/var/run/docker.sock %REGISTRY%/library/install-script:%TAG% feder8 init full --offline
) else (
    echo Could not find 'images.tar' in the current directory. Unable to continue.
    exit 1
)
