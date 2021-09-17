@ECHO off

docker pull harbor.honeur.org/library/install-script:2.0.0
docker run --rm -it --name feder8-installer -e CURRENT_DIRECTORY=%CD% -e IS_WINDOWS=true -e DOCKER_CERT_SUPPORT=false -v /var/run/docker.sock:/var/run/docker.sock harbor.honeur.org/library/install-script:2.0.0 feder8 init essentials