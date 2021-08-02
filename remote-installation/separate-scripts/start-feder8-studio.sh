if systemctl show --property ActiveState docker &> /dev/null; then
    DOCKER_CERT_SUPPORT=true
else
    DOCKER_CERT_SUPPORT=false
fi

docker network create feder8-net >/dev/null 2>&1 || true
docker run --rm -it --network feder8-net -e CURRENT_DIRECTORY=$(pwd) -e IS_WINDOWS=false -e DOCKER_CERT_SUPPORT=$DOCKER_CERT_SUPPORT -v /var/run/docker.sock:/var/run/docker.sock harbor.honeur.org/library/install-script:2.0.0 feder8 init feder8-studio