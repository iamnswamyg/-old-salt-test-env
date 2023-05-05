#!/bin/bash
SALT_PREFIX="kitchen"
SCRIPT_PREFIX=${SALT_PREFIX}"-fullnode"
STORAGE_PATH="/data/lxd/"${SCRIPT_PREFIX}
IP="10.120.11"
IFACE="eth0"
IP_SUBNET=${IP}".1/24"
SALT_POOL=${SCRIPT_PREFIX}"-pool"
SCRIPT_PROFILE_NAME=${SCRIPT_PREFIX}"-profile"
SCRIPT_BRIDGE_NAME=${SALT_PREFIX}"-br"
SALT_NAME=${SCRIPT_PREFIX}
IMAGE=${SALT_PREFIX}

IS_LOCAL=false

# check if jq exists
if ! snap list | grep jq >>/dev/null 2>&1; then
  sudo snap install jq 
fi
# check if lxd exists
if ! snap list | grep lxd >>/dev/null 2>&1; then
  sudo snap install lxd 
fi

image_names=( "${IMAGE}")

# Loop through the list of items
for image_name in "${image_names[@]}"
do
    if lxc image list --format=json | jq -r '.[] | .aliases' | jq -r '.[].name' | grep -q "$image_name"; then
        echo "Image $image_name is present locally"
        

        if [ $image_name = ${IMAGE} ]; then
            IMAGE=$image_name
            IS_LOCAL=true
            echo "Using image $image_name for master"
        fi
        
    fi
done

if ! ${IS_LOCAL}; then
  echo "This is not master, please use https://github.com/iamnswamyg/salt-infra-image.git to create master"
  exit 1
fi

# preparing master conf file
echo "interface: ${IP}.2
auto_accept: True">${PWD}/scripts/saltconfig/master.local.conf

# preparing minion conf file
    echo "master: ${IP}.2
id: ${SALT_NAME}">${PWD}/scripts/saltconfig/minion.local.conf



if ! [ -d ${STORAGE_PATH} ]; then
    sudo mkdir -p ${STORAGE_PATH}
fi

# creating the pool
lxc storage create ${SALT_POOL} btrfs 

#create network bridge
lxc network create ${SCRIPT_BRIDGE_NAME} ipv6.address=none ipv4.address=${IP_SUBNET} ipv4.nat=true

# creating needed profile
lxc profile create ${SCRIPT_PROFILE_NAME}

# editing needed profile
echo "config:
devices:
  ${IFACE}:
    name: ${IFACE}
    network: ${SCRIPT_BRIDGE_NAME}
    type: nic
  root:
    path: /
    pool: ${SALT_POOL}
    type: disk
name: ${SCRIPT_PROFILE_NAME}" | lxc profile edit ${SCRIPT_PROFILE_NAME} 


#create salt-master container
lxc init ${IMAGE} ${SALT_NAME} --profile ${SCRIPT_PROFILE_NAME}
lxc network attach ${SCRIPT_BRIDGE_NAME} ${SALT_NAME} ${IFACE}
lxc config device set ${SALT_NAME} ${IFACE} ipv4.address ${IP}.2
lxc start ${SALT_NAME} 

lxc storage volume create ${SALT_POOL} ${SALT_NAME}
lxc config device add ${SALT_NAME} ${SALT_POOL} disk pool=${SALT_POOL} source=${SALT_NAME} path=${STORAGE_PATH}
lxc config set ${SALT_NAME} security.nesting=true security.syscalls.intercept.mknod=true security.syscalls.intercept.setxattr=true

sudo lxc config device add ${SALT_NAME} ${SALT_NAME}-script-share disk source=${PWD}/scripts path=/lxd
sudo lxc config device add ${SALT_NAME} ${SALT_NAME}-salt-share disk source=${PWD}/salt-root/salt path=/srv/salt
sudo lxc config device add ${SALT_NAME} ${SALT_NAME}-pillar-share disk source=${PWD}/salt-root/pillar path=/srv/pillar
sudo lxc exec ${SALT_NAME} -- /bin/bash /lxd/${SALT_NAME}.sh
# save container as image
lxc stop ${SALT_NAME}
lxc publish ${SALT_NAME} --alias ${SALT_NAME} 
lxc start ${SALT_NAME}





    







