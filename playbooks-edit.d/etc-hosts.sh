#!/bin/bash
set -eo pipefail

cwd="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$cwd"/../resources.rc

log_announce "edit etc-hosts"

# /etc/hosts
add_to_etchosts() {
    if [ $# -lt 1 ]; then
        log_error "at least one host entry must be provided"
        return 1
    fi
    local playbook_file="$kubespray_dir"/roles/kubernetes/preinstall/tasks/0090-etchosts.yml
    local task_name="Add custom entries to /etc/hosts"
    local task=""" \n
- name: $task_name
  lineinfile:
    dest: /etc/hosts
    line: \"{{ item }}\"
    backup: yes
    state: present
    unsafe_writes: true
    insertafter: \"EOF\"
  loop:
"""
    for entry in "$@"; do
        task+="    - \"$entry\""$'\n'
    done

    # if $task_name exists, delete it along with its subsequent internal data    
    if grep "$task_name" "$playbook_file" >/dev/null 2>&1; then
        local start_line=$(grep -n "$task_name" "$playbook_file" | cut -d':' -f1)
        local end_line=""

        # find the first empty line after $start_line
        lines="$(grep -n -E '^\s*$' "$playbook_file" | cut -d':' -f1)"
        while IFS= read -r line; do
            if [ $line -ge $start_line ]; then
                end_line=$line
                break
            fi
        done <<< "${lines}"

        # if $task_name exists and is at the end of file (where it should be) abort!
        if [ -z $end_line ]; then return 2; fi
        
        # delete all lines between $start_line and $end_line
        for cnt in $(seq $((end_line + 1)) -1 $start_line); do
            sed -i "${cnt}d" "$playbook_file"
        done
    fi

    local line_number=$(grep -n 'name: Update facts' "$playbook_file" | cut -d':' -f1)
    line_number=$((line_number - 2))

    if ! grep "$task_name" "$playbook_file"; then
        while IFS= read -r line; do
            if [ -z "$line" ]; then continue; fi

            local pattern="$line_number"'i\'"${line//\//\\\/}"
            local print_pattern="${line_number}p"
            sedfile "$pattern" "$print_pattern" "$playbook_file"
            line_number=$((line_number + 1))
        done <<< "$task"
    fi
}
add_to_etchosts \
    "$(get_host_ip) $(hostname)" \
    "$(get_host_ip) ${registry_hostname}"

