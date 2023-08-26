#!/bin/bash
set -eo pipefail

cwd="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$cwd"/resources.rc

log_announce "inventory-copy"

if [ "$1" = "--keep-old-inventory" ]; then
    log_info "keeping old inventory"
    exit 0
fi

if [ -e "$target_inventory_dir" ]; then
    rm -rf "$target_inventory_dir"
    log_info "removed dir: $(cbasename "$target_inventory_dir")"
fi

if [ -e "$src_inventory_dir" ]; then
    cp -rp "$src_inventory_dir" "$inventories_dir"
    mv "$inventories_dir"/"$(basename "$src_inventory_dir")" \
       "$inventories_dir"/"$(basename "$target_inventory_dir")"
    log_info "copied dir: $(cbasename "$src_inventory_dir") -> $(cbasename "$target_inventory_dir")"
else
    cp -rp "$inventories_dir"/sample "$target_inventory_dir"
    log_info "copied dir: $(cbasename "$inventories_dir"/sample) -> $(cbasename "$target_inventory_dir")"
fi
