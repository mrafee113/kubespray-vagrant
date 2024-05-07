#!/bin/bash

certs_dir="REMOTE_VAGRANT_DIR"/certs
common_name="COMMON_NAME"

{
    mkdir -p /etc/docker/certs.d/"${common_name}"
    cp -v "$certs_dir"/registry.crt /etc/docker/certs.d/"${common_name}"/ca.crt
}

{
    mkdir -p /etc/containerd/certs.d/"${common_name}"
    cp -v "$certs_dir"/registry.crt /etc/containerd/certs.d/"${common_name}"/ca.crt
}
