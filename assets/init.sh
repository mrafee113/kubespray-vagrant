#!/bin/bash
set -eo pipefail
# This file is supposed to run on each machine to set it up for further provisioning.

sudo apt update
sudo apt install -y bzip2 tar
