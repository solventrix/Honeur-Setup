#!/usr/bin/env bash
set -eux

VERSION=2.0.2
TAG=$VERSION

docker build --pull --rm -f "Dockerfile" -t feder8/install-script:$TAG "."
