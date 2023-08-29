### Introduction

tl;dr: This is a bunch of bash scripts to help ease using kubespray on your local device.  

I wanted to deploy kubernetes on my local device with a hypervisor but I faced some problems to which this repository is the answer.  
- I kept forgetting what things I need to modify in the repo to make it work and accustomed to my needs.  
    - So I embedded the kubespray repo into my project and editted files on the fly. Every change is explicit. If something forgotten, you can just replace the kubespray git repo with the original one.  
- Living in Iran I faced with problems being forbidden (from inside and out) to download certain files and images.  
    - So I slowed down and modularized the process of downloading so that when needed, one can change VPNs or ISPs to download certain files.  
    - Also created a mechanism to store files and images externally for future use.  
    - Obviously I had to create other mechanisms to serve the files locally for kubespray.  
- There were also some very minor problems that prohibited kubespray from finishing, I fixed those too.  

> I set `set -eo pipefail` in every script so in case of any failures the process stops.  
> The file `resources.rc` is sourced in every script and all its content made available.  

### init.sh  
The point of this file is to provide an automated sample. It's like an executable roadmap that shows how the files should be executed at first glance.  
Feel free to modify it or follow it manually.  

### utils.rc
This file contains a bunch of functions to ease the writing of the scripts. It is `source`d in file `resources.rc` and therefore in every other script.  

- `cbasename`: In contrast to `basename`, this function gets the full path of a file or directory, and returns the only the part below the *ROOT* of the project.  
    - e.g. `/home/user/kubespray-vagrant/assets/offline-files` -> `/assets/offline-files`  
- echo functions  
    - These functions ease the use of `tput` so that output text can be colorful, bold, underlined, and dim.  
    - Their names are self-explanatory. Just look for `## echo functions` in file.  
- printing functions  
    - These functions are for standardizing logging in scripts. They use echo functions to perform their tasks.  
    - They use `(cbasename "$0")` as script filename, `${FUNCNAME{1}}` as name of the function where text was logged, and `${BASH_LINENO[0]}` as the line number where text was logged.  
    - Their names are also self-explanatory. Just look for `## printing functions` in file.
- `sedfile`  
    - Takes 3 arguments. `pattern`, `print_pattern` and `file`. And one optional `--regex`.  
    - The purpose of it is to modify the `file` with `sed` according to `pattern`, and then print the changes using `sed` according to `print_pattern`; all in one function call.  
- `set_yaml_var`  
    - Takes 3 arguments. `var_name`, `var_value`, and `file`. And an optional `--head`.
    - Its purpose is to change/set the value of a variable in a yaml file.  
    - If the variable doesn't already exist, by default it will be added to the end of the file. Unless `--head` is given, then it will be added to the beginning of the file. (pointless feature I know)  
- `verify_ip_addr`  
    - checks if an ip address is a valid ipv4 address using regex.  
    - in case it isn't valid, it returns `1`.  
- `get_vbox_interface`  
    - This function is used to use `VBoxManage` to find out the network interface of virtualbox and return its name.  
    - It does take one positional argument `machine_number` which should be an interger larger than `1` to take affect. It is the case since virtualbox is presumed to be able to have multiple interfaces.  
    - If command `VBoxManage` is not available, then it returns `1`.  
    - If it doesn't find the interface it returns `vboxnet0` because that usually is the interface.  
- `get_vagrant_ip_prefix`  
    - It finds and returns the value of the variable `subnet` from the vagrant config file. (find it in `resources.rc`)  
- `netplan_vbox_interface`  
    - Takes one argument `mode`. Its values can be `add`, `remove`, and `apply`.  
    - It modifies the first file in `/etc/netplan` that starts with `01-` and ends with `.yaml` to include or not include the ip address `[vagrant config subnet].1/24`.  
    - Also takes optional second argument ip address. It is used to override the ip address used in netplan.  
    - The point of the `apply` mode is to run `netplan apply`. But it is there because sometimes it should be run when the vbox machines are running to take affect.  
- `get_host_ip_ifconfig`  
    - uses `ifconfig` to acquire the host ip that is on the subnet returned by `get_vagrant_ip_prefix`  
    - In case it's not found, it returns `1`.  
- `get_host_ip_netplan`  
    - uses the first file in `/etc/netplan` that starts with `01-` and ends with `.yaml` to acquire the host ip.  
    - In case it's not found, it returns `1`.  
- `get_host_ip`  
    - Tries finding host ip using `get_host_ip_ifconfig` and `get_host_ip_netplan` in this order.  
    - If not found it returns `$(get_vagrant_ip_prefix).1`.  
- `filename_to_date`  
    - Gets one argument `filename`.  
    - It prints out the datetime in the format `%Y%m%d%H%M` suffixed with the original filename.  
    - e.g. `filename_to_date assets/offline-files/2023-08-14-10-37.list` -> `202308141037	assets/offline-files/2023-08-14-10-37.list`  
- `get_latest_offline_list`  
    - It takes two optional arguments `--files` and `--images` to choose between printing the latest offline file list or image list.  
    - It looks up the related directory (e.g. `$offline_files_dir`), then uses `filename_to_date` to sort the files and return the filename of the latest one.  
- `get_latest_offline_files_list`  
- `get_latest_offline_images_list`  
- `remove_file_or_dir`  
    - remove the file or directory path given via the first argument, with logging.  
- `docker_image_exists`  
    - Takes `image_name` as argument and checks if it exists. If it doesn't, it returns `1`. 
- `docker_images_exist`  
    - Takes one argument `images_list` which is a filepath.  
    - It iterates over the images in the file (plus `registry:latest`) and checks if they exist using `docker_image_exists`. If any of them doesn't exist it returns `1`.  
- `docker_image_to_filename`  
    - Takes argument `image` which is the name of an image.  
    - It changes the slashes `/` to dashes `-`, and the colons `:` to dashes `-`.  
- `docker_imagefile_exists`  
    - Takes 2 arguments `image` and `images_dir` and then checks if the imagefile exists in the directory or not. If it doesn't, it returns `1`.  
- `docker_imagefiles_exist`  
    - Takes one argument `images_list` and then iterates over its images and checks if each file exists or not. If any of them do not exist, it returns `1`.  
- `maintain_docker_container`  
    - Takes argument `container_name`.  
    - It handles the container.  
        - If `running`, do nothing.  
        - If `paused`, `docker unpause`.  
        - If `exited`, `docker start`.  
        - If status is something else, just print and tell admin to act accordingly. Also return `3`.  
        - If acquiring status failed, return `1`.
- `string_contains`  
    - Takes two arguments `line` and `string`.  
    - Checks if the `line` does contain the `string` (literally) or not. If it doesn't, it returns `1`.  
- `string_endswith`  
    - Takes two arguments `line` and `string`.  
    - Checks if line does end with `string` or not. If it doesn't, it returns `1`.  
- `string_rfind`  
    - Takes two arguments `string` and `substr`.  
    - It presumes that `string` does contain `substr`, and then returns the index number of the beginning of the last `substr`.  
- `string_find`  
    - Takes two arguments `string` and `substr`.  
    - It presumes that `string` does contain `substr`, and then returns the index number of the beginning of the first `substr`.  
- `catstrip`  
    - Takes one argument `filename`.  
    - It `cat`s the file and then uses python `str.strip` and then prints the result.  

### resources.rc  
This file contains some things for scripts to use, also it can be used for debugging. You can `source` it in a terminal (from any directory).  
- Things it contains:
    - Files and directories:
        - `root_dir` : the directory that the file `resources.rc` resides on.
        - `assets_dir=$root_dir/assets` : this directory contains a couple of things that are needed to be provided for kubespray...
        - `kubespray_backup_dir=$root_dir/kubespray.bak`
        - `kubespray_dir=$root_dir/kubespray`
        - `vagrantfile=$kubespray_dir/Vagrantfile`
        - `venv_dir=$root_dir/venv`
        - `inventories_dir=$kubespray_dir/inventory`
        - `src_inventory_dir=$assets_dir/inventory` : your actual inventory. if you want to modify things either manually or by modifying scripts, this is your directory.
        - `target_inventory_dir=$inventories_dir/user` : `user` is based on the value of `$inventory` in file `$assets_dir/Vagrantfile.conf`. this directory will be used by kubespray. `src_inventory_dir` will be copied here.
        - `inventory_edit_scripts_dir=$root_dir/inventory-edit-scripts` : contains a bunch of scripts to edit `src_inventory_dir`
        - `dest_working_dir=$kubespray_dir/vagrant` : this directory will be mounted inside each machine as `/vagrant`
        - `relative_working_dir` : `$dest_working_dir`, but relative to `$kubespray_dir`
        - `remote_working_dir=/vagrant/$relative_working_dir` : #bug It should be /vagrant... I think...
        - assets
            - `vagrantconf=$assets_dir/Vagrantfile.conf` : this configuration file is in ruby and the content will be passed on to the Vagrantfile inside kubespray.
            - `vbox_guest_additions_dir=$assets_dir/vbox-guest-additions`
            - `offline_files_dir=$assets_dir/offline-files` : this dir contains offline files. they are organized like this. there's a "%Y-%m-%d-%H-%D.list" that contains a list of links (they may be a bit weird but you'll find that out later in the docs). There's also a directory with the same name (minus the `.list`) that contains the downloaded files.
            - `offline_images_dir=$assets_dir/offline-images` : same as offline-files
            - `registry_volume_dir=$assets_dir/registry-volume` : this directory will be mounted persistent storage for docker private registry.
        - inventory files
            - `offline_file=$src_inventory_dir/group_vars/all/offline.yml`
            - `mirror_file=$src_inventory_dir/group_vars/all/mirror.yml`
            - `k8s_cluster_file=$src_inventory_dir/group_vars/k8s_cluster/k8s-cluster.yml`
            - `containerd_file=$src_inventory_dir/group_vars/all/containerd.yml`
    - web links
        - `kubespray_github_url="https://github.com/kubernetes-sigs/kubespray.git"`
        - `kubespray_release_version="v2.22.1"`

Also these directories will be created if they don't already exist:
- `assets_dir`
- `dest_working_dir`
- `vbox_guest_additions_dir`
- `offline_files_dir`
- `offline_images_dir`
- `registry_volume_dir`

### update-git.sh
If `kubespray_backup_dir` doesn't exist, it will be cloned. The clone will depend on `kubespray_release_version`. If it is empty, branch `main` will be cloned.  
If a branch is checked out in `kubespray_backup_dir`, it will be pulled.  
If `kubespray_dir` doesn't exist, it will be created by copying `kubespray_dir`.  

### vagrant-conf-copy.sh
It provides the `$vagrantconf` file for kubespray. So it is important to modify it before this script runs.  

### venv.sh
If the `venv_dir` does not exist a virtualenv will be created there.  
The venv at `venv_dir` will be activated and the `$kubespray_dir/requirements.txt` will be installed on pip.  

### inventory-init.sh
If optional argument `--reset` is provided, it will first remove `src_inventory_dir`.  
If directory `src_inventory_dir` doesn't exist, it will be created by copying `inventories_dir/sample`.  

### inventory-edit.sh
Takes the following arguments:
- `--offline-file`
- `--mirror-file`
- `--k8s-cluster-file`
- `--containerd-file`
- `--all`

Except for `--all`, every arg corresponds with a file in `$inventory_edit_scripts_dir`.  

### inventory-edit-scripts/
#### offline-files
#### mirror-file
#### k8s-cluster-file
#### containerd-file
### vbox-guest-additions.sh
### vagrantfile-edit.sh
### inventory-copy.sh
### generate-offline-lists.sh
### manage-offline-files
### manage-offline-images
### assets
#### docker-daemon.json
#### docker.sh
#### init.sh
#### offline-files/ and offline-images/
#### Vagrantfile.conf
#### vbox-guest-additions/
