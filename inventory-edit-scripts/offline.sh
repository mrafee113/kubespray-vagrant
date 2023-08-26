#!/bin/bash
set -eo pipefail
# to edit inv/group_vars/all/offline.yml

cwd="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$cwd"/../resources.rc

log_announce "edit $(cbasename $offline_file)"

host_ip=$(get_host_ip)

# ubuntu_repo_link="http://${host_ip}:8081/repository/ubuntu-jammy-utwentenl"
# set_yaml_var "ubuntu_repo" "$ubuntu_repo_link" "$offline_file"

# files
files_repo_link="http://${host_ip}:8080"
set_yaml_var "files_repo" "$files_repo_link" "$offline_file"

for kube in kubectl kubelet; do
    kube_link="{{ files_repo }}/$kube-{{ kube_version }}-linux-{{ image_arch }}"
    set_yaml_var "${kube}_download_url" "$kube_link" "$offline_file"
done

kubeadm_link="{{ files_repo }}/kubeadm-{{ kubeadm_version }}-linux-{{ image_arch }}"
set_yaml_var "kubeadm_download_url" "$kubeadm_link" "$offline_file"

cni_plugins_link="{{ files_repo }}/cni-{{ cni_version }}-linux-{{ image_arch }}.tgz"
set_yaml_var "cni_download_url" "$cni_plugins_link" "$offline_file"

crictl_link="{{ files_repo }}/crictl-{{ crictl_version }}-{{ ansible_system | lower }}-{{ image_arch }}.tar.gz"
set_yaml_var "crictl_download_url" "$crictl_link" "$offline_file"

etcd_link="{{ files_repo }}/etcd-{{ etcd_version }}-linux-{{ image_arch }}.tar.gz"
set_yaml_var "etcd_download_url" "$etcd_link" "$offline_file"

calicoctl_link="{{ files_repo }}/calicoctl-{{ calico_ctl_version }}-linux-{{ image_arch }}"
set_yaml_var "calicoctl_download_url" "$calicoctl_link" "$offline_file"

# actual calico
# this is really weird. The downloaded file name will be e.g. v3.25.1.tar.gz
#  I hope no other file will be like this. I have no solutions in mind to fix it.
calico_crds_link="{{ files_repo }}/calico-crds-{{ calico_version }}.tar.gz"
set_yaml_var "calico_crds_download_url" "$calico_crds_link" "$offline_file"

ciliumcli_link="{{ files_repo }}/ciliumcli-{{ cilium_cli_version }}-linux-{{ image_arch }}.tar.gz"
set_yaml_var "ciliumcli_download_url" "$ciliumcli_link" "$offline_file"

helm_link="{{ files_repo }}/helm-{{ helm_version }}-linux-{{ image_arch }}.tar.gz"
set_yaml_var "helm_download_url" "$helm_link" "$offline_file"

crun_link="{{ files_repo }}/crun-{{ crun_version }}-linux-{{ image_arch }}"
set_yaml_var "crun_download_url" "$crun_link" "$offline_file"

kata_link="{{ files_repo }}/kata-containers-{{ kata_containers_version }}-{{ ansible_architecture }}.tar.xz"
set_yaml_var "kata_containers_download_url" "$kata_link" "$offline_file"

cri_dockerd_link="{{ files_repo }}/cri-dockerd-{{ cri_dockerd_version }}-{{ image_arch }}.tgz"
set_yaml_var "cri_dockerd_download_url" "$cri_dockerd_link" "$offline_file"

runc_link="{{ files_repo }}/runc-{{ runc_version }}-{{ image_arch }}"
set_yaml_var "runc_download_url" "$runc_link" "$offline_file"

crio_link="{{ files_repo }}/crio-{{ crio_version }}-{{ image_arch }}.tar.gz"
set_yaml_var "crio_download_url" "$crio_link" "$offline_file"

skopeo_link="{{ files_repo }}/skopeo-{{ skopeo_version }}-linux-{{ image_arch }}"
set_yaml_var "skopeo_download_url" "$skopeo_link" "$offline_file"

containerd_link="{{ files_repo }}/containerd-{{ containerd_version }}-linux-{{ image_arch }}.tar.gz"
set_yaml_var "containerd_download_url" "$containerd_link" "$offline_file"

nerdctl_link="{{ files_repo }}/nerdctl-{{ nerdctl_version }}-{{ ansible_system | lower }}-{{ image_arch }}.tar.gz"
set_yaml_var "nerdctl_download_url" "$nerdctl_link" "$offline_file"

runsc_link="{{ files_repo }}/gvisor-runsc-{{ gvisor_version }}-{{ ansible_architecture }}"
set_yaml_var "gvisor_runsc_download_url" "$runsc_link" "$offline_file"

containerd_shim_link="{{ files_repo }}/gvisor-containerd-shim-runsc-{{ gvisor_version }}-{{ ansible_architecture }}"
set_yaml_var "gvisor_containerd_shim_runsc_download_url" "$containerd_shim_link" "$offline_file"

krew_link="{{ files_repo }}/krew-{{ krew_version }}-{{ host_os }}-{{ image_arch }}.tar.gz"
set_yaml_var "krew_download_url" "$krew_link" "$offline_file"

## absent links
youki_link="{{ files_repo }}/youki-{{ youki_version }}-linux.tar.gz"
set_yaml_var "youki_download_url" "$youki_link" "$offline_file"

yq_link="{{ files_repo }}/yq-{{ yq_version }}-linux-{{ image_arch }}"
set_yaml_var "yq_download_url" "$youki_link" "$offline_file"

# images
host_name=$(hostname)
docker_registry_link="${host_name}:5000"
for name in kube gcr github docker quay; do
    set_yaml_var "${name}_image_repo" "$docker_registry_link" "$offline_file"
done
