#!/bin/bash
set -eo pipefail

cwd="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$cwd"/resources.rc

GUEST_ADDITION_VERSION=7.0.6
GUEST_ADDITION_ISO=VBoxGuestAdditions_${GUEST_ADDITION_VERSION}.iso

filename="$vbox_guest_additions_dir/$GUEST_ADDITION_ISO"
if [ ! -e "$filename" ]; then
    log_warning "downloading VboxGuestAdditions iso with wget"
    wget -O "$filename" "http://download.virtualbox.org/virtualbox/${GUEST_ADDITION_VERSION}/${GUEST_ADDITION_ISO}"
else
    log_info "vbox-guest-additions: file already exists: $filename"
fi

cp -v "$vbox_guest_additions_dir"/*.iso "$dest_working_dir"
cp -v "$vbox_guest_additions_dir"/install-vbox-guest-additions.sh "$dest_working_dir" 
