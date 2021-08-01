@ECHO off

docker network create feder8-net
docker run --rm -it --network feder8-net -v /var/run/docker.sock:/var/run/docker.sock feder8/install-script:2.0.0 feder8 init config-server