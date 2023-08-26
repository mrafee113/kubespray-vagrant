#!/bin/bash
set -eo pipefail

cwd="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$cwd"/resources.rc

## args
arg_kubespray=false
arg_kubespray_backup=false
arg_venv=false
arg_vbox_guest_additions_iso=false
arg_offline_files=false
arg_inventory=false

arg_default=false
arg_full=false

display_usage() {
    help_test="""
Usage: $(cbasename $0) [options]
    --kubespray                  (=true)
    --kubespray-backup           (=false)
    --venv                       (=false)
    --vbox-guest-addition-iso    (=false)
    --offline-files              (=false)
    --offline-images             (=false)
    --inventory                  (=false)

    --default                    (=true if no arg provided else false)
    --full                       (=false)

    --help
"""
    log_help "$help_text"
}

if [ -z "$1" ]; then
    arg_default=true
elif [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    display_usage
    exit 0
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        --kubespray)
            arg_kubespray=true
            shift
            ;;
        --kubespray-backup)
            arg_kubespray_backup=true
            shift
            ;;
        --venv)
            arg_venv=true
            shift
            ;;
        --vbox-guest-additions-iso)
            arg_vbox_guest_additions_iso=true
            shift
            ;;
        --offline-files)
            arg_offline_files=true
            shift
            ;;
        --offline-images)
            arg_offline_images=true
            shift
            ;;
        --inventory)
            arg_inventory=true
            shift
            ;;
        --default)
            arg_default=true
            shift
            ;;
        --full)
            arg_full=true
            shift
            ;;
    esac
done

if [ "$arg_default" = "true" ]; then
    arg_kubepsray=true
fi

if [ "$arg_full" = "true" ]; then
    arg_kubespray=true
    arg_kubespray_backup=true
    arg_venv=true
    arg_vbox_guest_additions=true
    arg_offline_files=true
    arg_offline_images=true
    arg_inventory=true
fi

if [ "$arg_kubespray" = "true" ]; then
    remove_file_or_dir "$kubespray_dir"; fi
if [ "$arg_kubespray_backup" = "true" ]; then
    remove_file_or_dir "$kubespray_backup_dir"; fi
if [ "$arg_venv" = "true" ]; then
    remove_file_or_dir "$venv_dir"; fi
if [ "$arg_vbox_guest_additions_iso" = "true" ]; then
    remove_file_or_dir "$vbox_guest_additions_dir"/*.iso; fi
if [ "$arg_offline_files" = "true" ]; then
    remove_file_or_dir "$offline_files_dir"/*; fi
if [ "$arg_offline_images" = "true" ]; then
    remove_file_or_dir "$offline_images_dir"/*; fi
if [ "$arg_inventory" = "true" ]; then
    remove_file_or_dir "$src_inventory_dir"; fi
