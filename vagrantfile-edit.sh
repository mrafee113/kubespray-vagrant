#!/bin/bash
set -eo pipefail

cwd="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$cwd"/resources.rc

log_announce "edit Vagrantfile"

## args
arg_dl_keep_remote_cache=false
arg_vbox_guest_additions=false
arg_machine_init=false
arg_all=false

display_usage() {
  help_test="""
Usage: $(cbasename $0) [options]
    --download-keep-remote-cache
    --vbox-guest-additions
    --machine-init
    --all : If this is provided, all actions are taken regardless of any other flags provided.

    Note that If no options/flags are provided, no actions will be taken.
"""
  log_help "$help_text"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --download-keep-remote-cache)
      arg_dl_keep_remote_cache=true
      shift
      ;;
    --vbox-guest-additions)
      arg_vbox_guest_additions=true
      shift
      ;;
    --machine-init)
      arg_machine_init=true
      shift
      ;;
    --all)
      arg_all=true
      shift
      ;;
    *)
      echo "Invalid option: $1"
      display_usage
      ;;
  esac
done

if [ "$arg_all" = "true" ]; then
    arg_dl_keep_remote_cache="true"
    arg_vbox_guest_additions="true"
    arg_machine_init="true"
fi

download_keep_remote_cache() {
    if grep 'download_keep_remote_cache": "True"' "$vagrantfile" >/dev/null 2>&1; then
        return 0
    fi
    local pattern='s/"download_keep_remote_cache": "False"/"download_keep_remote_cache": "True"/'
    local print_pattern='/"download_keep_remote_cache":/p'
    sedfile "$pattern" "$print_pattern" "$vagrantfile"
}
if [ "$arg_dl_keep_remote_cache" = "true" ]; then
    download_keep_remote_cache
fi

vbox_guest_additions() {
    if grep 'node.vm.provision "vbox-guest-additions"' "$vagrantfile" >/dev/null 2>&1; then
        return 0
    fi
    local shell_code='node.vm.provision "vbox-guest-additions", :type => "shell", :path => "'"$relative_working_dir"'/install-vbox-guest-additions.sh"'
    local line_number=$(grep -n 'if i == $num_instances' "$vagrantfile" | cut -d':' -f1)
    local pattern="$((line_number))"'i\      '"$shell_code"
    local print_pattern="/vbox-guest-additions/p"
    sedfile "$pattern" "$print_pattern" "$vagrantfile"
}
if [ "$arg_vbox_guest_additions" = "true" ]; then
    vbox_guest_additions
fi

machine_init() {
    if grep 'node.vm.provision "init"' "$vagrantfile" >/dev/null 2>&1; then
        return 0
    fi

    cp -v "$assets_dir"/init.sh "$dest_working_dir"
    sed -i s@"DEBIAN_REPO_URL"@"${debian_repo_url}"@ "$dest_working_dir"/init.sh

    local shell_code='node.vm.provision "init", :type => "shell", :path => "'"$relative_working_dir"'/init.sh"'
    local line_number=$(grep -n 'if i == $num_instances' "$vagrantfile" | cut -d':' -f1)
    local pattern="$((line_number))"'i\      '"$shell_code"
    local print_pattern='/"init", :type => "shell"/p'
    sedfile "$pattern" "$print_pattern" "$vagrantfile"
}
if [ "$arg_machine_init" = "true" ]; then
    machine_init
fi

ansible_compatibility() {
    if grep 'ansible.compatibility_mode = "2.0"' "$vagrantfile" >/dev/null 2>&1; then
        return 0
    fi
    local option='ansible.compatibility_mode = "2.0"'
    local line_number=$(grep -n 'ansible.playbook = $playbook' "$vagrantfile" | cut -d':' -f1)
    local pattern="$((line_number + 1))"'i\          '"$option"
    local print_pattern='/.compatibility_mode = "/p'
    sedfile "$pattern" "$print_pattern" "$vagrantfile"
}
ansible_compatibility

ssh_pubkey() {
    if grep 'node.vm.provision "ssh-pubkey"' "$vagrantfile" >/dev/null 2>&1; then
        return 0
    fi
    cp -vp "$HOME/.ssh/id_rsa.pub" "$dest_working_dir"/host_id_rsa.pub
    cp -vp "${assets_dir}"/ssh-pubkey.sh "$dest_working_dir"
    sed -i s@"REMOTE_VAGRANT_DIR"@"$remote_working_dir"@ "$dest_working_dir"/ssh-pubkey.sh

    local shell_code='node.vm.provision "ssh-pubkey", :type => "shell", :path => "'"$relative_working_dir"'/ssh-pubkey.sh"'
    local line_number=$(grep -n 'if i == $num_instances' "$vagrantfile" | cut -d':' -f1)
    local pattern="$((line_number))"'i\      '"$shell_code"
    local print_pattern='/"ssh-pubkey", :type => "shell"/p'
    sedfile "$pattern" "$print_pattern" "$vagrantfile"
}
if [ "$arg_machine_init" = "true" ]; then
    ssh_pubkey
fi

registry_certs() {
    if grep 'node.vm.provision "registry-certs"' "$vagrantfile" >/dev/null 2>&1; then
        return 0
    fi
    cp -vp "${assets_dir}"/certs.sh "$dest_working_dir"
    sed -i s@"REMOTE_VAGRANT_DIR"@"$remote_working_dir"@ "$dest_working_dir"/certs.sh
    sed -i s@"COMMON_NAME"@"$registry_hostname"@ "$dest_working_dir"/certs.sh

    local shell_code='node.vm.provision "registry-certs", :type => "shell", :path => "'"$relative_working_dir"'/certs.sh"'
    local line_number=$(grep -n 'if i == $num_instances' "$vagrantfile" | cut -d':' -f1)
    local pattern="$((line_number))"'i\      '"$shell_code"
    local print_pattern='/"registry-certs", :type => "shell"/p'
    sedfile "$pattern" "$print_pattern" "$vagrantfile"
}
if [ "$arg_machine_init" = "true" ]; then
    registry_certs
fi
