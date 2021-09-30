if systemctl show --property ActiveState docker &> /dev/null; then
    DOCKER_CERT_SUPPORT=true
else
    DOCKER_CERT_SUPPORT=false
fi

if [[ $OSTYPE == 'darwin'* ]]; then
  IS_MAC=true
else
  IS_MAC=false
fi

VERSION=2.0.1
TAG=$VERSION

docker pull harbor-dev.honeur.org/library/install-script:$TAG
docker run --rm -it --name feder8-installer -e CURRENT_DIRECTORY=$(pwd) -e IS_WINDOWS=false -e IS_MAC=$IS_MAC -e DOCKER_CERT_SUPPORT=$DOCKER_CERT_SUPPORT -v /var/run/docker.sock:/var/run/docker.sock harbor-dev.honeur.org/library/install-script:$TAG feder8 init essentials
