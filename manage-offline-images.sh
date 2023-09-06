#!/bin/bash
set -eo pipefail

cwd="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$cwd"/resources.rc

print_help() {
    help="""
$(cbasename "$0") [mode] [images.list]
    images.list (optional): the name (only the name) of the files.list e.g. 2023-08-02-13-12.list
    mode:
        - 'download': to pull docker images
        - 'export': to extract the images from docker into a directory and then a tarball
        - 'cleanup': to remove the pulled docker images from docker itself
        - 'serve': to extract a tarball and load push it into a docker registry at localhost:5000
        - 'check': to visually check which images have not been served
        - 'served': to check whether all images have been served or not. for script use.
"""
    log_help "$help"
}

help_list_file() {
    log_info "- generate files list."
    log_code "  ./generate-offline-lists.sh"
    printf "\n"

    print_help
}

# arg --help-list-file
if [ "$1" = "--help-list-file" ]; then
    help_list_file
    exit 0
fi

# validate arg mode
if [ -z "$1" ]; then
    log_error "download? export? or serve?"
    print_help
    exit 1
fi
mode="$1"
shift

if [ ! "$mode" = "download" ] && [ ! "$mode" = "export" ] && \
   [ ! "$mode" = "cleanup"  ] && [ ! "$mode" = "serve"  ] && \
   [ ! "$mode" = "check"    ] && [ ! "$mode" = "served" ]; then
    log_error "$mode is not a valid option"
    print_help
    exit 1
fi

# validate arg images_list
if [ -z "$1" ] && ! get_latest_offline_images_list >/dev/null 2>&1; then
    log_error "no file.list found or given."
    exit 1
fi

# setting vars
images_list="$offline_images_dir"/"$(get_latest_offline_images_list)"
if [ -n "$1" ] && [[ "$1" == *.list ]]; then
    images_list="$offline_files_dir"/"$1"
fi
images_dir="${images_list%.list}"
images_txt="${images_list%.list}.txt"
images_tar="${images_list%.list}.tar"
if [ -n "$1" ] && [[ "$1" == *.tar ]]; then
    images_tar="$1"
fi

download() {
    log_announce "download mode"
    images_progress="$offline_images_dir"/images.progress
    if [ ! -e "$images_progress" ]; then touch "$images_progress"; fi
    if [ ! -e "$images_list" ]; then
        log_error "file $(cbasename "$images_list") does not exist!" 
        return 1
    fi

    sort "$images_list" > /tmp/images.list
    sort "$images_progress" > /tmp/images.progress
    comm -23 /tmp/images.list /tmp/images.progress > /tmp/images.dl
    
    if ! grep 'registry:latest' /tmp/images.progress; then
        echo 'registry:latest' >> /tmp/images.dl
    fi
    local max=$(cat /tmp/images.dl | wc -l)
    local cnt=1
    for image in $(cat /tmp/images.dl); do
        log_info "pulling $cnt/$max $image at $(date '+%H:%M')"
        st=$(date +%s.%N)
        
        set +e
        retry_count=5
        for step in $(seq 1 ${retry_count}); do
            docker pull $image
            if [ $? -eq 0 ]; then
                echo "$image" >> "$images_progress"
                break
            fi
            log_error "failed to pull ${image} at step ${step}"
            if [ ${step} -eq ${retry_count} ]; then
                return 1
            fi
        done
        set -e

        et=$(date +%s.%N)
        duration=$(echo "$et - $st" | bc)
        duration=$(date -d@$duration -u "+%H' %M\" %Ss")
        size=$(docker images $image --format '{{ .Size }}')
        log_info "$cnt/$max pull done with size $size within $duration"
        cnt=$((cnt + 1))
    done
    log_info "download complete."

    sort "$images_list" > /tmp/images.list
    sort "$images_progress" > /tmp/images.progress
    comm -23 /tmp/images.list /tmp/images.progress > /tmp/images.dl
    if [ -n "$(cat /tmp/images.dl)" ]; then
        log_warning """the following images have not been able to download.
$(cat /tmp/images.dl)"""
    else
        for file in "$images_progress" \
            /tmp/images.list \
            /tmp/images.progress \
            /tmp/images.dl; do
            remove_file_or_dir "$file"
        done
    fi
}

export_() {
    log_announce "export mode"
    mkdir -vp "$images_dir"
    local max=$(cat "$images_list" | wc -l)
    local cnt=1
    for image in $(cat "$images_list" | sort); do
        file_name="$(docker_image_to_filename ${image}).tar"
        docker save -o "$images_dir"/"$file_name" ${image}

        size=$(du -sh "$images_dir"/"$file_name" | awk '{print $1}')
        log_info "saved $cnt/$max ${image} with size $size"
        
        # for kubespray
        first_part=$(echo ${image} | awk -F"/" '{print $1}')
        if [ "$first_part" = "registry.k8s.io" ] ||
           [ "$first_part" = "gcr.io" ] ||
           [ "$first_part" = "docker.io" ] ||
           [ "$first_part" = "quay.io" ]; then
            image=$(echo ${image} | sed s@"${first_part}/"@@)
        fi
        echo "${file_name}  ${image}" >> ${images_txt}
        cnt=$((cnt + 1))
    done
    docker save -o "$images_dir"/registry-latest.tar registry:latest
    # tar -zcvf "${images_tar}" "${images_dir}"
    # log_info "images exported to $(cbasename "$images_tar")"
    # log_info "you can feel free to delete the temp images dir $(cbasename "$images_dir")}"
    log_info "feel free to clean up your docker images referring to file $(cbasename "$images_list")"
}

cleanup() {
    log_announce "cleanup mode"

    cp "$images_list" /tmp/images.tmp
    if [ "$1" = "--tagged-images" ] || [ "$2" = "--tagged-images" ] || [ "$3" = "--tagged-images" ]; then
        for image in $(cat /tmp/images.tmp); do
            first_part=$(echo ${image} | awk -F"/" '{print $1}')
            if [ "$first_part" = "registry.k8s.io" ] ||
               [ "$first_part" = "gcr.io" ] ||
               [ "$first_part" = "docker.io" ] ||
               [ "$first_part" = "quay.io" ]; then
                tagged_image=$(echo ${image} | sed s@"${first_part}/"@@)
            else
                tagged_image="$image"
            fi
            tagged_image="${registry_hostname}/${tagged_image}"
            echo "$tagged_image" >> /tmp/images.tmp
        done
    fi

    leftovers=""
    local cnt=1
    local max=$(cat "/tmp/images.tmp" | wc -l)
    for image in $(cat "/tmp/images.tmp"); do
        set +e
        docker image inspect "$image" >/dev/null 2>&1
        exit_code=$?
        set -e
        if [ $exit_code -ne 0 ]; then
            continue
        fi

        set +e
        docker image rm "$image"
        exit_code=$?
        set -e
        if [ $exit_code -eq 0 ]; then
            log_info "removed image $cnt/$max $image"
        else
            leftovers+="${image}\n"
        fi
        cnt=$((cnt + 1))
    done

    if [ -n "$leftovers" ]; then
        log_warning """these images were not removed... act accordingly.
$leftovers"""
    fi
    remove_file_or_dir /tmp/images.tmp
}

serve() {
    log_announce "serve mode"
    # if [ ! -e "$images_tar" ]; then
    #     log_error "file $(cbasename "$images_tar") does not exist!"
    #     return 1
    # fi
    if [ ! -e "$images_txt" ]; then
        log_error "file $(cbasename "$images_txt") does not exist! have you exported images yet?"
        return 1
    fi
    mkdir -vp ${images_dir}
    
    # tar -zxvf "${images_tar}"
    docker load -i "${images_dir}"/registry-latest.tar
    $root_dir/registry.sh

    local cnt=1
    local max=$(cat "$images_txt" | wc -l)
    while read -r line; do
        file_name=$(echo ${line} | awk '{print $1}')
        raw_image=$(echo ${line} | awk '{print $2}')
        new_image="${registry_hostname}/${raw_image}"
        org_image=$(docker load -i "${images_dir}"/"${file_name}" | head -n1 | awk '{print $3}')
        image_id=$(docker image inspect ${org_image} --format '{{.Id}}' | awk -F: '{print $2}')
        if [ -z "${file_name}" ]; then
            echo "Failed to get file_name for line ${line}"
            exit 1
        fi
        if [ -z "${raw_image}" ]; then
            echo "Failed to get raw_image for line ${line}"
            exit 1
        fi
        if [ -z "${org_image}" ]; then
            echo "Failed to get org_image for line ${line}"
            exit 1
        fi
        if [ -z "${image_id}" ]; then
            echo "Failed to get image_id for file ${file_name}"
            exit 1
        fi
        log_info "serving $cnt/$max $line"
        docker image load -i "${images_dir}"/"${file_name}"
        docker image tag ${image_id} ${new_image}
        docker image push ${new_image}
        cnt=$((cnt + 1))
    done <<< "$(cat ${images_txt})"
}

check() {
    log_announce "check mode"
    if [ ! -e "$images_txt" ]; then
        log_error "file $(cbasename "$images_txt") does not exist! have you exported images yet?"
        return 1
    fi
    
    local cnt=1
    local max=$(cat "$images_txt" | wc -l)
    while read -r line; do
        raw_image=$(echo ${line} | awk '{print $2}')
        served_image="${registry_hostname}/${raw_image}"
        if docker_image_exists "$served_image"; then
            log_info "$cnt/$max: $served_image"
        else
            log_error "$cnt/$max: $served_image"
        fi
        cnt=$((cnt + 1))
    done <<< "$(cat ${images_txt})"
}

served() {
    if [ ! -e "$images_txt" ]; then
        log_error "file $(cbasename "$images_txt") does not exist! have you exported images yet?"
        return 1
    fi

    while read -r line; do
        raw_image=$(echo ${line} | awk '{print $2}')
        served_image="${registry_hostname}/${raw_image}"
        if ! docker_image_exists "$served_image"; then
            exit 1
        fi
    done <<< "$(cat ${images_txt})"
    exit 0
}

if [ "$mode" = "download" ]; then download $*
elif [ "$mode" = "export" ]; then export_ $*
elif [ "$mode" = "cleanup" ]; then cleanup $*
elif [ "$mode" = "serve" ]; then serve $*
elif [ "$mode" = "check" ]; then check $*
elif [ "$mode" = "served" ]; then served $*
fi
