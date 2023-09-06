#!/bin/bash
set -eo pipefail

cwd="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$cwd"/resources.rc

cn="${registry_common_name}"

if [ -f "$certs_dir"/registry.key ] && [ -f "$certs_dir"/registry.crt ]; then
    cp -rvp "$certs_dir" "$dest_working_dir"
    exit 0
else
    remove_file_or_dir "$certs_dir"
    mkdir -p "$certs_dir"
fi

openssl req \
    -newkey rsa:4096 \
    -nodes \
    -sha256 \
    -keyout "$certs_dir"/registry.key \
    -subj "/CN=${cn}" \
    -addext "subjectAltName = DNS:${cn}" \
    -x509 \
    -days 365 \
    -out "$certs_dir"/registry.crt

sudo mkdir -p /usr/local/share/ca-certificates/"$cn"
sudo cp "$certs_dir"/registry.crt /usr/local/share/ca-certificates/"$cn"
sudo update-ca-certificates

sudo mkdir -p /etc/docker/certs.d/"$cn"
sudo cp -v "$certs_dir"/registry.crt /etc/docker/certs.d/"$cn"/ca.crt

if [ ! `cat /etc/hosts | grep -o "${cn}"` ]; then
    echo "127.0.0.1 ${cn}" | sudo tee -a /etc/hosts
fi

cp -rvp "$certs_dir" "$dest_working_dir"/
