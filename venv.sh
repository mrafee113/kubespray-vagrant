#!/bin/bash
set -eo pipefail

cwd="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$cwd"/resources.rc

log_announce "venv"

python_bin="/usr/bin/python3"
for v in {15..1}; do
    if [ -e "/usr/bin/python3.${v}" ]; then
        python_bin+=".${v}"
    fi
done

if [ ! -e "$venv_dir" ]; then
    virtualenv --python="$python_bin" "$venv_dir"
    log_info "created venv at: $venv_dir"
fi

source "$venv_dir"/bin/activate
log_info "installing on pip from $kubespray_dir/requirements.txt..."

if curl http://localhost:10809 >/dev/null 2>&1; then
    pip install --proxy http://localhost:10809 -U -r "$kubespray_dir"/requirements.txt
else
    pip install -U -r "$kubespray_dir"/requirements.txt
fi
