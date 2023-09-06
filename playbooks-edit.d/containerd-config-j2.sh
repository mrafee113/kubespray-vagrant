#!/bin/bash
set -eo pipefail

cwd="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$cwd"/../resources.rc

log_announce "edit containerd-config-j2"

# /etc/hosts
add_ca_cert_to_config_template() {
    local config_file="$kubespray_dir"/roles/container-engine/containerd/templates/config.toml.j2
    local iteration="""
{% if containerd_ca_registries is defined and containerd_ca_registries|length>0 %}
{% for registry, addr in containerd_ca_registries.items() %}
        [plugins.\"io.containerd.grpc.v1.cri\".registry.mirrors.\"{{ registry }}\"]
          endpoint = [\"{{ ([ addr ] | flatten ) | join('\",\"') }}\"]
        [plugins.\"io.containerd.grpc.v1.cri\".registry.configs.\"{{ addr | urlsplit('netloc') }}\".tls]
          ca = \"/etc/containerd/certs.d/{{ registry }}/ca.crt\"
{% endfor %}
{% endif %}
"""
    if grep "containerd_ca_registries" "$config_file" >/dev/null 2>&1; then
        return
    fi
    line_number=$(grep -n -E '{% if containerd_insecure_registries is defined and containerd_insecure_registries|length>0 %}' "$config_file" | cut -d':' -f1)
    while IFS= read -r line; do
        if [ -z "$line" ]; then continue; fi
        
        pattern="${line_number}"'i\'"${line//\%/\\\%}"
        print_pattern="${line_number}p"
        sedfile "$pattern" "$print_pattern" "$config_file"
        line_number=$((line_number + 1))
    done <<< "$iteration"   
}
add_ca_cert_to_config_template

