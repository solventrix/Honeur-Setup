#!/usr/bin/env bash
set -eux

VERSION="${VERSION:=2.0.19}" # set by bump2version
TAG=$VERSION

docker tag feder8/install-script:$TAG $THERAPEUTIC_AREA_URL/library/install-script:$TAG
docker push $THERAPEUTIC_AREA_URL/library/install-script:$TAG
