#!/bin/bash
set -eo pipefail

cwd="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$cwd"/resources.rc

cn="${registry_common_name}"

openssl req \
    -newkey rsa:4096 \
    -nodes \
    -sha256 \
    -keyout "$certs_dir"/domain.key \
    -subj "/CN=${cn}" \
    -addext "subjectAltName = DNS:${cn}" \
    -x509 \
    -days 365 \
    -out "$certs_dir"/domain.crt
exit 0

if [ -f "$certs_dir"/"$cn".key ] && [ -f "$certs_dir"/"$cn".crt ]; then
    exit 0
else
    remove_file_or_dir "$certs_dir"
    mkdir -p "$certs_dir"
fi

# CA
openssl genpkey \
    -algorithm RSA \
    -out "$certs_dir"/ca.key \
    -pkeyopt rsa_keygen_bits:2048
openssl req \
    -new \
    -key "$certs_dir"/ca.key \
    -subj "/CN=${cn}" \
    -out "$certs_dir"/ca.csr
openssl x509 \
    -req \
    -in "$certs_dir"/ca.csr \
    -signkey "$certs_dir"/ca.key \
    -out "$certs_dir"/ca.crt \
    -days 3650

# docker registry: unused
cat > "$certs_dir"/"$cn".conf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = $(hostname)
IP.1 = $(get_host_ip)
EOF

openssl genpkey \
    -algorithm RSA \
    -out "$certs_dir"/"$cn".key \
    -pkeyopt rsa_keygen_bits:2048
openssl req \
    -new \
    -key "$certs_dir"/"$cn".key \
    -subj "/CN=${cn}" \
    -addext "subjectAltName = DNS:${cn}" \
    -out "$certs_dir"/"$cn".csr
openssl x509 \
    -req \
    -in "$certs_dir"/"$cn".csr \
    -CA "$certs_dir"/ca.crt \
    -CAkey "$certs_dir"/ca.key \
    -CAcreateserial \
    -out "$certs_dir"/"$cn".crt \
    -days 3650

sudo mkdir -p /usr/local/share/ca-certificates/"$cn"
sudo cp "$certs_dir"/ca.crt /usr/local/share/ca-certificates/"$cn"
sudo update-ca-certificates

sudo mkdir -p "/etc/docker/certs.d/$cn"
sudo cp -v "$certs_dir"/ca.crt "/etc/docker/certs.d/$cn/ca.crt"

if [ ! `cat /etc/hosts | grep -o "${cn}"` ]; then
    echo "127.0.0.1 ${cn}" | sudo tee -a /etc/hosts
fi

cp -vp "$certs_dir" "$dest_working_dir"/
