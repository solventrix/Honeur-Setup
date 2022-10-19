#!/usr/bin/env bash
docker rmi $(docker images --filter=reference="harbor-uat.honeur.org/honeur/*:*" -q)
docker rmi $(docker images --filter=reference="harbor-uat.phederation.org/phederation/*:*" -q)
docker rmi $(docker images --filter=reference="harbor-uat.esfurn.org/esfurn/*:*" -q)
