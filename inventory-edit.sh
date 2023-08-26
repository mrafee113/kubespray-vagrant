#!/bin/bash
set -eo pipefail

cwd="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$cwd"/resources.rc

## args
arg_offline_file=false
arg_mirror_file=false
arg_k8s_cluster_file=false
arg_containerd_file=false
arg_all=false

display_usage() {
  help_test="""
Usage: $(cbasename $0) [options]
    --offline-file
    --mirror-file       
    --k8s-cluster-file
    --containerd-file
    --all : If this is provided, all actions are taken regardless of any other flags provided.

    Note that If no options/flags are provided, no actions will be taken.
"""
  log_help "$help_text"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --offline-file)
      arg_offline_file=true
      shift
      ;;
    --mirror-file)
      arg_mirror_file=true
      shift
      ;;
    --k8s-cluster-file)
      arg_k8s_cluster_file=true
      shift
      ;;
    --containerd-file)
      arg_containerd_file=true
      shift
      ;;
    --all)
      arg_all=true
      shift
      ;;
    *)
      echo "Invalid option: $1"
      display_usage
      ;;
  esac
done

if [ "$arg_all" = "true" ]; then
    arg_offline_file=true
    arg_mirror_file=true
    arg_k8s_cluster_file=true
    arg_containerd_file=true
fi

if [ "$arg_offline_file" = "true" ]; then
    $inventory_edit_scripts_dir/offline.sh
fi

if [ "$arg_mirror_file" = "true" ]; then
    $inventory_edit_scripts_dir/mirror.sh --ubuntu
    $inventory_edit_scripts_dir/mirror.sh --ubuntu-usages
fi

if [ "$arg_k8s_cluster_file" = "true" ]; then
    $inventory_edit_scripts_dir/k8s-cluster.sh
fi

if [ "$arg_containerd_file" = "true" ]; then
    $inventory_edit_scripts_dir/containerd.sh
fi
