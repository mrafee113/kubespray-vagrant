#!/bin/bash
set -eo pipefail

cwd="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$cwd"/resources.rc

filename="$vbox_guest_additions_dir/$vbox_guest_additions_iso"
if [ ! -e "$filename" ]; then
    log_warning "downloading VboxGuestAdditions iso with wget"
    wget -O "$filename" "$vbox_guest_additions_url"
else
    log_info "vbox-guest-additions: file already exists: $filename"
fi

cp -v "$vbox_guest_additions_dir"/*.iso "$dest_working_dir"
cp -v "$vbox_guest_additions_dir"/install-vbox-guest-additions.sh "$dest_working_dir" 
