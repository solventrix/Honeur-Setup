#!/usr/bin/env bash
docker rmi $(docker images --filter=reference="harbor-dev.honeur.org/honeur/*:*" -q)
docker rmi $(docker images --filter=reference="harbor-dev.phederation.org/phederation/*:*" -q)
docker rmi $(docker images --filter=reference="harbor-dev.esfurn.org/esfurn/*:*" -q)
