#!/usr/bin/env bash
set -eux

VERSION=2.0.7
TAG=$VERSION

docker tag feder8/install-script:$TAG $THERAPEUTIC_AREA_URL/library/install-script:$TAG
docker push $THERAPEUTIC_AREA_URL/library/install-script:$TAG
