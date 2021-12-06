#!/usr/bin/env bash
set -eux

VERSION=awsagunva-2.0.10
TAG=$VERSION
THERAPEUTIC_AREA_URL=harbor.honeur.org

docker tag feder8/install-script:$TAG $THERAPEUTIC_AREA_URL/library/install-script:$TAG
docker push $THERAPEUTIC_AREA_URL/library/install-script:$TAG
