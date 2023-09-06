#!/bin/bash
set -eo pipefail
# to edit inv/group_vars/k8s_cluster/k8s-cluster.yml

cwd="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$cwd"/../resources.rc

log_announce "edit $(cbasename "$k8s_cluster_file")"

# kube_version=1.26.7
# set_yaml_var "kube_version" "$kube_version" "$k8s_cluster_file"

set_yaml_var "kubectl_localhost" "true" "$k8s_cluster_file"
set_yaml_var "kubeconfig_localhost" "true" "$k8s_cluster_file"
