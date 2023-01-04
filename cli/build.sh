#!/usr/bin/env bash
set -eux

VERSION="${VERSION:=2.0.21}" # set by bump2version
TAG=$VERSION

docker build --no-cache --pull --rm -f "Dockerfile" -t feder8/install-script:$TAG "."
