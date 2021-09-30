@ECHO off

docker pull harbor-dev.honeur.org/library/install-script:2.0.1
docker run --rm -it --name feder8-installer -e CURRENT_DIRECTORY=%CD% -e IS_WINDOWS=true -e DOCKER_CERT_SUPPORT=false -v /var/run/docker.sock:/var/run/docker.sock harbor-dev.honeur.org/library/install-script:2.0.1 feder8 init feder8-studio
