docker network create feder8-net >/dev/null 2>&1 || true
docker pull harbor.honeur.org/library/install-script:2.0.0
docker run --rm -it --network feder8-net -v /var/run/docker.sock:/var/run/docker.sock harbor.honeur.org/library/install-script:2.0.0 feder8 init atlas-webapi