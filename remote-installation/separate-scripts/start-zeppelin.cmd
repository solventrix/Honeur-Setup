@ECHO off

docker network create feder8-net
docker run --rm -it --network feder8-net -e CURRENT_DIRECTORY=%CD% -e IS_WINDOWS=true -v /var/run/docker.sock:/var/run/docker.sock feder8/install-script:2.0.0 feder8 init zeppelin