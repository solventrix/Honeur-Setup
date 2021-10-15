#!/usr/bin/env bash

unset DOCKER_HOST
unset DOCKER_TLS_VERIFY
DOCKER_SERVICE_OVERRIDE="/etc/systemd/system/docker.service.d/override.conf"
if [ -f "$DOCKER_SERVICE_OVERRIDE" ]; then
    echo "Removing TLS configuration"
    sudo rm -v $DOCKER_SERVICE_OVERRIDE
    echo "Restarting Docker..."
    sudo systemctl daemon-reload
    sudo systemctl restart docker
fi
echo "Stop and remove authorization broker container if exists"
docker stop authz-broker > /dev/null 2>&1 || true
docker rm authz-broker > /dev/null 2>&1 || true
echo "Docker TLS security successfully disabled"