#!/bin/usr/env bash
set -e

volume="pgdata"

if [ "$1" = "" ]
then
        echo "Please provide the backup file to restore from"
        exit
fi

if [ "$2" != "" ]
then
        volume="$2"
fi

docker run -v ${volume}:/volume -v $PWD:/backup --rm loomchild/volume-backup restore $1
