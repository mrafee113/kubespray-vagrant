#!/bin/bash
set -eo pipefail

GUEST_ADDITION_VERSION=7.0.6
GUEST_ADDITION_ISO=VBoxGuestAdditions_${GUEST_ADDITION_VERSION}.iso
GUEST_ADDITION_MOUNT=/media/VBoxGuestAdditions

apt-get install -y linux-headers-$(uname -r) build-essential dkms

cp -v /vagrant/"${GUEST_ADDITION_ISO}" /home/vagrant
mkdir -p ${GUEST_ADDITION_MOUNT}
mount -o loop,ro ${GUEST_ADDITION_ISO} ${GUEST_ADDITION_MOUNT}
sh ${GUEST_ADDITION_MOUNT}/VBoxLinuxAdditions.run
