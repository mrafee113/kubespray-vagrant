#!/bin/bash
set -eo pipefail

cwd="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$cwd"/resources.rc

set +e
maintain_docker_container registry
status_code=$?
set -e

if [ "$status_code" -eq 0 ]; then
    exit 0
fi

if [ "$status_code" -eq 3 ]; then
    docker container stop registry
    docker container rm registry
fi

docker run \
    -d \
    --restart=always \
    --name registry \
    -v "$certs_dir":/certs \
    -v "$assets_dir"/registry-volume:/var/lib/registry \
    -e REGISTRY_HTTP_ADDR=0.0.0.0:443 \
    -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/registry.crt \
    -e REGISTRY_HTTP_TLS_KEY=/certs/registry.key \
    -p 443:443 \
    registry:latest
