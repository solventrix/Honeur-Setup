if [[ $OSTYPE == 'darwin'* ]]; then
  IS_MAC=true
else
  IS_MAC=false
fi

docker pull harbor-uat.honeur.org/library/install-script:2.0.0
docker run --rm -it --name feder8-installer -e IS_MAC=$IS_MAC -v /var/run/docker.sock:/var/run/docker.sock harbor-uat.honeur.org/library/install-script:2.0.0 feder8 init local-portal
