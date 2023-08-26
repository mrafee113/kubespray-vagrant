#!/bin/bash
set -eo pipefail

cwd="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$cwd"/resources.rc

log_announce "vagrant up help"
printf "\n"

log_code "      source $(cbasename $venv_dir)/bin/activate"
log_code "      VAGRANT_CWD=$kubespray_dir $(tput setaf 3)or$(tput sgr0) $(tput dim setaf 5)cd kubespray$(tput sgr0)"
log_code "      vagrant up --no-provision"
log_warning """   You have to start up the machines, then run
     some code to make the host machine take a static ip that is configured in the scripts.
     Then you should run the vagrantfile along with the provisioning so that
     the links to the host ip work properly. e.g. offline links.
     Note(!) that the 'netplan_vbox_interface' only works after the VMs are up."""
log_code "      source /resources.rc"
log_code "      netplan_vbox_interface add"
log_info "      'netplan_vbox_interface' also accepts 'remove'!"
log_code "      vagrant up --provision --provision-with shell"
log_code "      vagrant up --provision --provision-with ansible"

printf "\n"
log_info  "after deployment: you can copy \$artifacts_dir/admin.conf to ~/.kube/config"
