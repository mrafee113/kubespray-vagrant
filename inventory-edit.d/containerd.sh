#!/bin/bash
#set -eo pipefail
# to edit inv/group_vars/all/containerd.yml

cwd="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$cwd"/../resources.rc

log_announce "edit $(cbasename "$containerd_file")"

docker_line='"'"docker.io"'": "'"https://registry-1.docker.io"'"'
registry_line='"'"${registry_hostname}"'": "'"https://${registry_hostname}"'"'

set_yaml_list "containerd_registries" "$containerd_file" \
    "$docker_line"

set_yaml_list "containerd_ca_registries" "$containerd_file" \
    "$registry_line"
