docker pull harbor-dev.honeur.org/library/install-script:2.0.0
docker run --rm -it --name feder8-installer -v /var/run/docker.sock:/var/run/docker.sock harbor-dev.honeur.org/library/install-script:2.0.0 feder8 init user-management
