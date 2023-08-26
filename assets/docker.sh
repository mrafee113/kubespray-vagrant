#!/bin/bash

sudo echo "IP_ADDR HOSTNAME" >> /etc/hosts

sudo mkdir -vp /etc/docker
sudo cp "DST" /etc/docker/daemon.json
