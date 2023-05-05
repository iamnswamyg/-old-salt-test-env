#!/bin/bash

SCRIPT_IMAGE="salt-fullnode"


image_names=("${SCRIPT_IMAGE}")

# Loop through the list of items
for image_name in "${image_names[@]}"
do
    if lxc image list --format=json | jq -r '.[] | .aliases' | jq -r '.[].name' | grep -q "$image_name"; then
        echo "Deleting Image $image_name is locally"
        sudo lxc image delete $image_name
    fi
done

echo "listing the images"
lxc image list --format=json | jq -r '.[] | .aliases' | jq -r '.[].name' 