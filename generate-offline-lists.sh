#!/bin/bash
set -eo pipefail

# This file is replacement for "$kubespray_dir"/contrib/offline/generate_list.sh
#  Instead of just producing a files.list which is a file containing urls,
#   each line contains the filename too.
#  images.list is the same.

cwd="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$cwd"/resources.rc

download_yml_file="$kubespray_dir"/roles/download/defaults/main.yml
if [ -n "$DOWNLOAD_YML" ]; then download_yml_file="$DOWNLOAD_YML"; fi
contrib_offline_dir="$kubespray_dir"/contrib/offline
temp_dir=$(mktemp -d)

# generate all download files url/filename template > files.list.template
files_content=$(grep 'download_url:' "$download_yml_file")
files_content_tmp=""
while IFS= read -r line; do
    name=$(echo "$line" | cut -d':' -f1 | sed 's|_download_url||g')
    if [ -z "$name" ]; then continue; fi

    version=""
    for version_template in        \
        "{{ ${name}_version }}"    \
        "{{ kube_version }}"       \
        "{{ calico_ctl_version }}" \
        "{{ calico_version }}"     \
        "{{ cilium_cli_version }}" \
        "{{ gvisor_version }}"
    do
        if string_contains "$line" "$version_template"; then
            version="$version_template"
            break
        fi
    done

    os=""
    for os_template in \
        "{{ ansible_system | lower }}" \
        "{{ host_os }}"                \
        "linux"                        
    do
        if string_contains "$line" "$os_template"; then
            os="$os_template"
            break
        fi
    done

    arch=""
    for arch_template in \
        "{{ image_arch }}"           \
        "{{ ansible_architecture }}"
    do
        if string_contains "$line" "$arch_template"; then
            arch="$arch_template"
            break
        fi
    done

    format=""    
    for format_template in \
        "tar.gz" \
        "tgz"    \
        "tar.xz"
    do
        if string_endswith "$line" "$format_template"'"'; then
            format="$format_template"
            break
        fi
    done

    line=$(echo "$line" | sed 's/^.*_url: //g;s/\"//g')

    # manage exception: youki_url
    if [[ "$name" == *youki* ]]; then
        f1=$(echo "$line" | awk -F'}}/youki_' '{print $1}')
        f2=$(echo "$line" | awk -F'}}/youki_' '{print $2}')
        if [[ "$f2" == v* ]]; then
            f2=$(echo "$f2" | awk -F'v{{' '{print "{{"$2}')
        fi
        line="${f1}}}/youki_{{ 'v' if youki_version == '0.0.1' else '' }}${f2}"
    fi

    # create filename
    filename=""
    name=$(echo "$name" | sed 's|_|-|g')
    for var in "${name}" "-${version}" "-${os}" "-${arch}" ".${format}"; do
        v="${var#-}"; v="${v#.}"; v="${v#-}"
        if [ -n "$v" ]; then
            filename+="$var"
        fi
    done

    line+=" DOWNLOADER_PREFIX:${filename}"
    files_content_tmp+="${line}"$'\n'
done <<< "$files_content"
echo "${files_content_tmp%$'\n'}" > "$temp_dir"/files.list.template

# generate all images list template > images.list.template
sed -n '/^downloads:/,/download_defaults:/p' "$download_yml_file" \
    | sed -n "s/repo: //p;s/tag: //p" | tr -d ' ' \
    | sed 'N;s#\n# #g' | tr ' ' ':' | sed 's/\"//g' > "$temp_dir"/images.list.template

# add kube-* images to images list template
# Those container images are downloaded by kubeadm, then roles/download/defaults/main.yml
# doesn't contain those images. That is reason why here needs to put those images into the
# list separately.
KUBE_IMAGES="kube-apiserver kube-controller-manager kube-scheduler kube-proxy"
for i in $KUBE_IMAGES; do
    echo "{{ kube_image_repo }}/$i:{{ kube_version }}" >> ${temp_dir}/images.list.template
done

# run ansible to expand templates
/bin/cp "$contrib_offline_dir"/generate_list.yml "$kubespray_dir"
pattern="s|./contrib/offline/temp/|${temp_dir}/|"
print_pattern="/${temp_dir//\//\\\/}\//p"
sedfile "$pattern" "$print_pattern" "$kubespray_dir"/generate_list.yml

(cd "$kubespray_dir" && ansible-playbook $* generate_list.yml && /bin/rm generate_list.yml) || exit 1

name="$(date '+%Y-%m-%d-%H-%M').list"
cp "$temp_dir"/files.list  "$offline_files_dir"/"$name"
cp "$temp_dir"/images.list "$offline_images_dir"/"$name"
remove_file_or_dir "$temp_dir"
