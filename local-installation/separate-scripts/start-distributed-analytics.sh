docker pull harbor-dev.honeur.org/library/install-script:2.0.1
docker run --rm -it --name feder8-installer -e CURRENT_DIRECTORY=$(pwd) -e IS_WINDOWS=false -v /var/run/docker.sock:/var/run/docker.sock harbor-dev.honeur.org/library/install-script:2.0.1 feder8 init distributed-analytics
