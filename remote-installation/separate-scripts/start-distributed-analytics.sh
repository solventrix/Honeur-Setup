
docker pull harbor.honeur.org/library/install-script:2.0.0
docker run --rm -it --name feder8-installer -e CURRENT_DIRECTORY=$(pwd) -e IS_WINDOWS=false -v /var/run/docker.sock:/var/run/docker.sock harbor.honeur.org/library/install-script:2.0.0 feder8 init distributed-analytics
