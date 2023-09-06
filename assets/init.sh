#!/bin/bash
set -eo pipefail
# This file is supposed to run on each machine to set it up for further provisioning.

debian_repo_url="DEBIAN_REPO_URL"
if [ -n "$debian_repo_url" ]; then
    sudo sed -i -E "s|^deb https?://[^ ]*|deb ${debian_repo_url}|g" "/etc/apt/sources.list"
fi

sudo apt update
sudo apt install -y bzip2 tar net-tools
