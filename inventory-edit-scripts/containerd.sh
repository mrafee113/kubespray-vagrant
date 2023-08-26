#!/bin/bash
#set -eo pipefail
# to edit inv/group_vars/all/containerd.yml

cwd="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$cwd"/../resources.rc

log_announce "edit $(cbasename "$containerd_file")"

host_ip=$(get_host_ip)
line='"'"${host_ip}:5000"'": "'"http://${host_ip}:5000"'"'

commented=$(grep -n -E '^# containerd_insecure_registries:.*$' "$containerd_file" 2>/dev/null)
uncommented=$(grep -n -E '^containerd_insecure_registries:.*$' "$containerd_file" 2>/dev/null)
if [ -z "$commented" ] && [ -z "$uncommented" ]; then
    # doesn't exist
    echo "containerd_insecure_registries:"$'\n''  '"$line" >> "$containerd_file"
elif [ -n "$commented" ]; then
    # commented
    pattern='s|^#\s?containerd_insecure_registries:.*$|containerd_insecure_registries:|g'
    print_pattern="/.*containerd_insecure_registries.*/p"
    sedfile "$pattern" "$print_pattern" "$containerd_file" --regex
    
    line_number=$(grep -n -E '^containerd_insecure_registries:.*$' "$containerd_file" | cut -d':' -f1)
    line_number=$((line_number + 1))
    pattern="$line_number"'i\  '"${line//\//\\\/}"
    print_pattern="${line_number}p"
    sedfile "$pattern" "$print_pattern" "$containerd_file"
else
    # not commented
    line_number=$(grep -n -E "^\s*${line}.*$" "$containerd_file" | cut -d':' -f1)
    if [ -z "$line_number" ]; then
        line_number=$(grep -n -E '^containerd_insecure_registries:.*$' "$containerd_file" | cut -d':' -f1)
        line_number=$((line_number + 1))
        pattern="$line_number"'i\  '"${line//\//\\\/}"
        print_pattern="${line_number}p"
        sedfile "$pattern" "$print_pattern" "$containerd_file"
    fi
fi
