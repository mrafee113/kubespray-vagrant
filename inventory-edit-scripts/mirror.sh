#!/bin/bash
set -eo pipefail
# to edit inv/group_vars/all/mirror.yml

cwd="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$cwd"/../resources.rc

log_announce "edit $(cbasename "$mirror_file")"

if [ ! -e "$mirror_file" ]; then
    cp -p "$kubespray_backup_dir"/inventory/sample/group_vars/all/offline.yml "$mirror_file"
    log_info "copied: $(cbasename "$mirror_file")"
fi

# these links do not work, but they were advised by kubespray public mirror docs
# https://github.com/kubernetes-sigs/kubespray/blob/master/docs/mirror.md

case "$1" in
    --files-repo)
        # uncomment the usages of "files_repo"
        pattern='/# .*\{\{ files_repo/s/^# //g'
        print_pattern='/[^#]*\{\{ files_repo/p'
        sedfile "$pattern" "$print_pattern" "$mirror_file" --regex
        ;;
    --chinese)
        set_yaml_var "gcr_image_repo" "gcr.m.daocloud.io" "$mirror_file"
        set_yaml_var "kube_image_repo" "k8s.m.daocloud.io" "$mirror_file"
        set_yaml_var "docker_image_repo" "docker.m.daocloud.io" "$mirror_file"
        set_yaml_var "quay_image_repo" "quay.m.daocloud.io" "$mirror_file"
        set_yaml_var "github_image_repo" "ghcr.m.daocloud.io" "$mirror_file"
        set_yaml_var "files_repo" "https://files.m.daocloud.io" "$mirror_file"
        ;;
    --iranrepo-ir)
        set_yaml_var "kube_image_repo" "docker.iranrepo.ir" "$mirror_file"
        set_yaml_var "docker_image_repo" "docker.iranrepo.ir" "$mirror_file"
        ;;
    --ubuntu)
        set_yaml_var "ubuntu_repo" "http://ftp.snt.utwente.nl/pub/os/linux/ubuntu" "$mirror_file"
        ;;
    --ubuntu-usages)
        pattern='/# .*\{\{ ubuntu_repo/s/^# //g'
        print_pattern='/[^#]*\{\{ ubuntu_repo/p'
        sedfile "$pattern" "$print_pattern" "$mirror_file" --regex
        ;;
esac
