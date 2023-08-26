#!/bin/bash
set -eo pipefail

cwd="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$cwd"/resources.rc

log_announce "inventory-init"

if [ "$1" = "--reset" ]; then
    $root_dir/reset.sh --inventory; fi

if [ ! -e "$src_inventory_dir" ]; then
    cp -rp "$inventories_dir"/sample "$assets_dir"
    mv "$assets_dir"/sample "$src_inventory_dir"
    log_info "created dir: $src_inventory_dir"
fi
