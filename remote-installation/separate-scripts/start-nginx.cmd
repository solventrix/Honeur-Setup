@ECHO off

docker network create feder8-net
docker run --rm -it --network feder8-net -v /var/run/docker.sock:/var/run/docker.sock harbor.honeur.org/library/install-script:2.0.0 feder8 init nginx