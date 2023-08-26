#!/bin/bash
set -eo pipefail

cwd="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$cwd"/resources.rc

print_help() {
    help="""
$(cbasename $"0") [mode] [files.list]
    files.list (optional): the name (only the name) of the files.list e.g. 2023-08-02-13-12.list
    mode:
        - 'download' to download the files
        - 'check' to check downloaded files
        - 'serve' to start nginx
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
    log_error "download?, check? or serve?"
    print_help
    exit 1
fi
mode="$1"
shift

if [ ! "$mode" = "download" ] && [ ! "$mode" = "serve" ] && [ ! "$mode" = "check" ]; then
    log_error "$mode is not a valid option"
    print_help
    exit 1
fi

# validate arg files_list
if [ -z "$1" ] && ! get_latest_offline_files_list >/dev/null 2>&1; then
    log_error "no file.list found or given."
    exit 1
fi

# setting vars
files_list="$offline_files_dir"/"$(get_latest_offline_files_list)"
if [ -n "$1" ]; then
    files_list="$offline_files_dir"/"$1"
fi
files_dir="${files_list%.list}"

# validate files_list's existence
if [ ! -e "$files_list" ]; then
    log_error "file $(cbasename "$files_list") does not exist!!"
    help_list_file
    exit 1
fi

download() {
    log_announce "download mode"
    mkdir -vp "$files_dir"
    if command -v "aria2c" >/dev/null 2>&1; then
        if [ -e "$HOME/.aria2c" ]; then
            conf="$HOME/.aria2c"
        else
            conf="$HOME/.aria2/aria2.conf"
        fi
        log_warning "downloading with aria2c"
        input_file="$files_list"

        if string_contains "$(cat "$input_file")" "DOWNLOADER_PREFIX:"; then
            sed 's| DOWNLOADER_PREFIX:|\n\tout=|g' "$input_file" > /tmp/links.list
            input_file=/tmp/links.list
            aria2c --conf-path="$conf" --dir "$files_dir" --input-file="$input_file" --max-concurrent-downloads=5 --optimize-concurrent-downloads=true 
        else
            aria2c --conf-path="$conf" --dir "$files_dir" --input-file="$input_file"
        fi
    elif command -v "wget" >/dev/null 2>&1; then
        log_warning "downloading with wget"
        if string_contains "$(cat "$files_list")" "DOWNLOADER_PREFIX:"; then
            while IFS= read -r line; do
                url=$(echo "$line" | awk -F' DOWNLOADER_PREFIX:' '{print $1}')
                filename=$(echo "$line" | awk -F' DOWNLOADER_PREFIX:' '{print $2}')
                wget --force-directories --directory-prefix="$files_dir" --output-document="$filename"
            done <<< "$(cat "$files_list")"
        else
            wget --force-directories --directory-prefix="$files_dir" --input-file="$files_list"
        fi
    else
        log_error "neither aria2c nor wget commands were available."
        exit 1
    fi
}

check() {
    log_announce "check mode"
    log_warning "It's always best if you check it yourself too."
    local log=""$'\n'

    local number_log=""
    local operator=""
    local number_of_lines=$(catstrip "$files_list" | wc -l)
    local number_of_files=$(ls -1 "$files_dir" | wc -l)
    if [ $number_of_lines -eq $number_of_files ]; then
        number_log+="OK::"
        operator="match"
    else
        number_log+="ERR:"
        operator="do not match"
    fi
    number_log+=" the number of lines ($number_of_lines) $operator the number of files ($number_of_files)"
    log+="$number_log"$'\n'

    while IFS= read -r line; do
        if string_contains "$line" "DOWNLOADER_PREFIX:"; then
            local filename=$(echo "$line" | awk -F' DOWNLOADER_PREFIX:' '{print $2}')
            local url=$(echo "$line" | awk -F' DOWNLOADER_PREFIX' '{print $1}')
            if ls -1 "$files_dir" 2>/dev/null | grep "$filename" >/dev/null 2>&1; then
                log+="OK:: $filename  ::  $url"$'\n'
            else
                log+="ERR: $url"$'\n'
            fi
        else
            local err_log="ERR: $line"
            local last_slash=$(string_rfind "$line" '/')
            if [ -z "$last_slash" ]; then
                log+="$err_log"$'\n'
                continue
            fi
            local first_dash=$(string_find  "${line:$last_slash}" '-')
            if [ -z "$first_dash" ]; then
                log+="$err_log"$'\n'
                continue
            fi
            local name="${line:$last_slash:$first_dash}"
            if [ -z "$name" ] || ! ls -1 "$files_dir" 2>/dev/null | grep "$name" >/dev/null 2>&1; then
                log+="$err_log"$'\n'
                continue
            fi
            log+="OK:: $line"$'\n'
        fi
    done <<< "$(cat "$files_list")"
    
    log_info "$log"
}

serve() {
    log_announce "serve mode"
    container_name=kubespray-offline-nginx
    image_name="nginx:alpine"
    set +e
    maintain_docker_container "$container_name"
    exit_code=$?
    if   [ $exit_code -eq 3 ]; then
        exit 1
    elif [ $exit_code -eq 0 ]; then
        log_info "docker container $container_name is already running"
    elif [ $exit_code -eq 1 ]; then
        run_text="""
docker run \
    --restart=always --detach --publish 8080:80 \
    --volume "${files_dir}:/usr/share/nginx/html/download" \
    --volume "${assets_dir}/offline-files-nginx.conf":/etc/nginx/nginx.conf \
    --name $container_name \
    $image_name
"""
        log_code "$run_text"
        docker run \
            --restart=always --detach --publish 8080:80 \
            --volume "${files_dir}:/usr/share/nginx/html/download" \
            --volume "${assets_dir}/offline-files-nginx.conf":/etc/nginx/nginx.conf \
            --name $container_name \
            $image_name
    fi
}

if   [ "$mode" = "download" ]; then download
elif [ "$mode" = "check"    ]; then check
elif [ "$mode" = "serve"    ]; then serve
fi
