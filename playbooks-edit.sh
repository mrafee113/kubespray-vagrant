#!/bin/bash
set -eo pipefail

cwd="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$cwd"/resources.rc

## args
arg_containerd_config_j2=false
arg_etc_hosts=false
arg_all=false

display_usage() {
    log_help """
Usage: $(cbasename $0) [options]
    --containerd-config-j2
    --etc-hosts
    --all : If this is provided, all actions are taken regardless of any other flags provided.

    Note that If no options/flags are provided, no actions will be taken.
"""
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --containerd-config-j2)
            arg_containerd_config_j2=true
            shift
            ;;
        --etc-hosts)
            arg_etc_hosts=true
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
    arg_containerd_config_j2=true
    arg_etc_hosts=true
fi

if [ "$arg_containerd_config_j2" = "true" ]; then
    $playbooks_edit_scripts_dir/containerd-config-j2.sh
fi

if [ "$arg_etc_hosts" = "true" ]; then
    $playbooks_edit_scripts_dir/etc-hosts.sh
fi
