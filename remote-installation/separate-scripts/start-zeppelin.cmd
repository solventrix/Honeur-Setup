@ECHO off

docker pull harbor.honeur.org/library/install-script:2.0.0
docker run --rm -it -e CURRENT_DIRECTORY=%CD% -e IS_WINDOWS=true -v /var/run/docker.sock:/var/run/docker.sock harbor.honeur.org/library/install-script:2.0.0 feder8 init zeppelin