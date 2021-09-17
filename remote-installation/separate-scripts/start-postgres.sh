docker pull harbor-uat.honeur.org/library/install-script:2.0.0
docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock harbor-uat.honeur.org/library/install-script:2.0.0 feder8 init postgres
