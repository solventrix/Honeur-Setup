#!/usr/bin/env bash
set -eux

VERSION=2.0.12
TAG=$VERSION

docker build --no-cache --pull --rm -f "Dockerfile" -t feder8/install-script:$TAG "."
