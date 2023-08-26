#!/bin/bash
set -eo pipefail

# This is a sample default setup.
#  If you don't like it, feel free to modify it, or follow it manually.

cwd="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$cwd"/resources.rc

## args
args=("update-git" "vagrant-conf-copy" "venv" "inventory-init" \
    "inventory-edit" "inventory-copy" "vbox-guest-additions" "vagrantfile-edit"  \
    "generate-offline-lists" "manage-offline-files" "manage-offline-images" \
    "vagrant-up-help")
for arg in ${args[*]}; do
    # add exceptions here
    if [ "$arg" = "vbox-guest-additions" ] || [ "$arg" = "generate-offline-lists" ]
        then continue; fi
    var_name="arg_${arg//-/_}"
    declare $var_name="true"
done
arg_vbox_guest_additions="false"
arg_generate_offline_lists="false"

arg_all=false

display_usage() {
    tmp="$(cbasename "$0")"
    help_test="""
Usage: $(cbasename "$0") [options]
    --update-git
    --vagrant-conf-copy
    --venv
    --inventory-init
    --inventory-edit
    --inventory-copy
    --vbox-guest-additions
    --vagrantfile-edit
    --generate-offline-lists
    --[no]-manage-offline-files
    --[no]-manage-offline-images
    --vagrant-up-help
    --all : If this is provided, all actions are taken regardless of any other flags provided.

    Note that If no options/flags are provided, the default flags will be:
        --update-git --vagrant-conf-copy --venv \
        --inventory-init --inventory-edit --inventory-copy \
        --vagrantfile-edit --vagrant-up-help
"""
    log_help "$help_test"
}

arg_no_manage_offline_files="false"
arg_no_manage_offline_images="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help)
      display_usage
      exit 0
      ;;
    --update-git)
      arg_update_git=true
      shift
      ;;
    --vagrant-conf-copy)
      arg_vagrant_conf_copy=true
      shift
      ;;
    --venv)
      arg_venv=true
      shift
      ;;
    --inventory-init)
      arg_inventory_init=true
      shift
      ;;
    --inventory-edit)
      arg_inventory_edit=true
      shift
      ;;
    --inventory-copy)
      arg_inventory_copy=true
      shift
      ;;
    --vbox-guest-additions)
      arg_vbox_guest_additions=true
      shift
      ;;
    --vagrantfile-edit)
      arg_vagrantfile_edit=true
      shift
      ;;
    --generate-offline-lists)
      arg_generate_offline_lists=true
      shift
      ;;
    --manage-offline-files)
      arg_manage_offline_files=true
      shift
      ;;
    --manage-offline-images)
      arg_manage_offline_images=true
      shift
      ;;
    --vagrant-up-help)
      arg_vagrant_up_help=true
      shift
      ;;
    --no-manage-offline-files)
      arg_no_manage_offline_files=true
      shift
      ;;
    --no-manage-offline-images)
      arg_no_manage_offline_images=true
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
    for arg in ${args[*]}; do
        var_name="arg_${arg//-/_}"
        declare $var_name="true"
    done
fi

if [ "$arg_no_manage_offline_files" = "true" ]; then
    arg_manage_offline_files="false"
fi
if [ "$arg_no_manage_offline_images" = "true" ]; then
    arg_manage_offline_images="false"
fi


if [ "$arg_update_git" = "true" ]; then
    $root_dir/update-git.sh
fi
if [ "$arg_vagrant_conf_copy" = "true" ]; then
    $root_dir/vagrant-conf-copy.sh
fi
if [ "$arg_venv" = "true" ]; then
    $root_dir/venv.sh
fi
if [ "$arg_inventory_init" = "true" ]; then
    $root_dir/inventory-init.sh --reset
fi
if [ "$arg_inventory_edit" = "true" ]; then
    $root_dir/inventory-edit.sh --offline-file --k8s-cluster-file --mirror-file
fi
if [ "$arg_vbox_guest_additions" = "true" ]; then
    $root_dir/vbox-guest-additions.sh
fi
if [ "$arg_vagrantfile_edit" = "true" ]; then
    $root_dir/vagrantfile-edit.sh --download-keep-remote-cache --machine-init
fi
if [ "$arg_inventory_copy" = "true" ]; then
    $root_dir/inventory-copy.sh
fi
if [ "$arg_generate_offline_lists" = "true" ]; then
    $root_dir/generate-offline-lists.sh
fi
if [ "$arg_manage_offline_files" = "true" ]; then
    set +e
    files_list=$(get_latest_offline_files_list)
    error_code=$?
    set -e
    if [ $error_code -gt 0 ]; then
        log_error "no files.list found in $(cbasename "$offline_files_dir")"
        $root_dir/manage-offline-files.sh --help-list-file
        exit 1
    fi
    if [ ! -e "${offline_files_dir}/${files_list%.list}" ]; then
        $root_dir/manage-offline-files.sh download
    fi
    $root_dir/manage-offline-files.sh serve
fi
if [ "$arg_manage_offline_images" = "true" ]; then
    set +e
    images_list=$(get_latest_offline_images_list)
    exit_code=$?
    set -e
    if [ $exit_code -gt 0 ]; then
        log_error "no images.list found in $(cbasename "$offline_images_dir")"
        $root_dir/manage-offline-images.sh --help-list-file
    fi
    images_list="${offline_images_dir}/${images_list}"

    set +e
    docker_images_exist "$images_list"
    exit_code=$?
    set -e
    if   [ $exit_code -eq 1 ]; then
        $root_dir/manage-offline-images.sh download
    elif [ $exit_code -eq 2 ]; then
        exit 1
    fi
    
    set +e
    docker_imagefiles_exist "$images_list"
    exit_code=$?
    set -e
    if   [ $exit_code -eq 1 ]; then
        $root_dir/manage-offline-images.sh "export"
    elif [ $exit_code -eq 2 ]; then
        exit 1
    fi

    $root_dir/manage-offline-images.sh serve
    $root_dir/manage-offline-images.sh cleanup
fi
if [ "$arg_vagrant_up_help" = "true" ]; then
    $root_dir/vagrant-up-help.sh
fi

## todos
#echo "\n" assets/inventory/group_vars/k8s_cluster/k8s-cluster.yml :: local_release_dir: "/tmp/releases" :: change this shit
#echo " "configure calico_datastore = \"etcd\" 
