docker network create feder8-net >/dev/null 2>&1 || true
docker pull harbor-uat.honeur.org/library/install-script:2.0.0
docker run --rm -it --network feder8-net -e CURRENT_DIRECTORY=$(pwd) -e IS_WINDOWS=false -v /var/run/docker.sock:/var/run/docker.sock harbor-uat.honeur.org/library/install-script:2.0.0 feder8 init distributed-analytics
