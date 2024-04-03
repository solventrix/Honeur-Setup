@ECHO off

SET TAG=2.0.30
SET REGISTRY=harbor.honeur.org
SET DOCKER_CERT_SUPPORT=false
SET IS_MAC=false
SET IS_WINDOWS=true

echo "Pull local installation script"
docker pull %REGISTRY%/library/install-script:%TAG%

echo "Upgrade Feder8 Studio"
docker run --rm -it --name feder8-installer -e CURRENT_DIRECTORY=%CD% -e IS_WINDOWS=true -e IS_MAC=false -e DOCKER_CERT_SUPPORT=false -v /var/run/docker.sock:/var/run/docker.sock %REGISTRY%/library/install-script:%TAG% feder8 init feder8-studio -ta honeur

echo "Upgrade DiTrAn"
docker run --rm -it --name feder8-installer -e CURRENT_DIRECTORY=%CD% -e IS_WINDOWS=true -e IS_MAC=false -e DOCKER_CERT_SUPPORT=false -v /var/run/docker.sock:/var/run/docker.sock %REGISTRY%/library/install-script:%TAG% feder8 init ditran -ta honeur
