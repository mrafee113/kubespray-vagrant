#!/bin/bash
set -eo pipefail
# This is used to setup assets/Vagrantfile.conf

cwd="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$cwd"/resources.rc

log_announce "copy Vagrantfile.conf"
mkdir -p "$dest_working_dir"
cp -vp "$vagrantconf" "$dest_working_dir"/config.rb
