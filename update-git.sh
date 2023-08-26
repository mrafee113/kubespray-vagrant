#!/bin/bash
set -eo pipefail

cwd="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$cwd"/resources.rc

log_announce "update git"

if [ ! -e "$kubespray_backup_dir" ]; then
    log_info "cloning $kubespray_github_url"
    
    git clone "$kubespray_github_url" "$kubespray_backup_dir"
    if [ -n "$kubespray_release_version" ]; then
        git -C "$kubespray_backup_dir" checkout $kubespray_release_version
    fi

    log_info "created dir: $(cbasename $kubespray_backup_dir)"
elif [ -n "$(git -C "$kubespray_backup_dir" branch --show-current)" ]; then
    log_info "fetching and pulling repo"
    git -C "$kubespray_backup_dir" fetch
    git -C "$kubespray_backup_dir" pull
else
    log_info "already up to date."
fi

if [ ! -e "$kubespray_dir" ]; then
    cp -rp "$kubespray_backup_dir" "$kubespray_dir"
    log_info "created dir: $(cbasename $kubespray_dir)"
fi
