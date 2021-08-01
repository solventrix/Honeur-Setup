docker network create feder8-net >/dev/null 2>&1 || true
docker run --rm -it --network feder8-net -v /var/run/docker.sock:/var/run/docker.sock feder8/install-script:2.0.0 feder8 init zeppelin