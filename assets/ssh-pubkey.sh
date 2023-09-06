#!/bin/bash

pubkey_file="REMOTE_VAGRANT_DIR"/host_id_rsa.pub
authorized_keys_file="/home/vagrant/.ssh/authorized_keys"

if [ -f "$authorized_keys_file" ]; then
    authorized_keys="$(cat "$authorized_keys_file")"
else
    authorized_keys=""
fi

if [[ ! "$authorized_keys" == *"$(cat "$pubkey_file")"* ]]; then
    cat "$pubkey_file" >> /home/vagrant/.ssh/authorized_keys
fi
