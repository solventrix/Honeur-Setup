#!/usr/bin/env bash
set -eux

VERSION="${VERSION:=2.0.19}"
TAG=$VERSION

docker build --no-cache --pull --rm -f "Dockerfile" -t feder8/install-script:$TAG "."
