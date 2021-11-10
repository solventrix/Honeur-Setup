#!/usr/bin/env bash
docker rmi $(docker images --filter=reference="harbor.honeur.org/honeur/*:*" -q)
docker rmi $(docker images --filter=reference="harbor.phederation.org/phederation/*:*" -q)
docker rmi $(docker images --filter=reference="harbor.esfurn.org/esfurn/*:*" -q)
