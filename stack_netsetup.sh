#!/bin/sh
# This script creates a basic network infrastraucture for an openstack project
# It checks to see if a network already exists
# It uses a random network segment address, checking to see if one exists already
# The network names are defaulted to use the given project name
# but it replaces all spaces with an underscore to ensure it works for all projects

echo "Please enter the project you wish to create a basic network for"
read -r project

#Check to see if the project exists
tenant=$(keystone tenant-list | awk "/$project/ {print \$2}")
echo "$tenant"

#Check to see if the project exists
if [ -z "$tenant" ];
then
        echo "That project doesnt exist, exiting"
        exit 0
fi

netcheck="false"

#until [ -z "$netcheck" ]; do

        # Generate random number for network segment
        net_sec=$(( $RANDOM % 250 + 2 ));

        network_cidr="192.168.${net_sec}"

        # Check to see if the random network selection is being used
        netcheck=$(neutron subnet-list | awk "/$network_cidr/ {print \$2}")
        
#done

network_cidr="${network_cidr}.0/24"

echo "Network to be used is ${network_cidr}"

# Check to see if project has a network already

test=$(neutron net-list --tenant-id ${tenant})

echo "$test"

if  [ -z "$test" ];
then
        echo "Creating network for $project project replacing spaces with _"
        echo "tenant id is ${tenant}"
        neutron net-create --tenant-id ${tenant} ${project// /_}_net
        neutron subnet-create --tenant-id ${tenant} --dns-nameserver 8.8.8.8 --name ${project// /_}_snet ${project// /_}_net $network_cidr
        neutron router-create --tenant-id ${tenant} ${project// /_}_r
        neutron router-gateway-set ${project// /_}_r ext_net
        neutron router-interface-add ${project// /_}_r ${project// /_}_snet
else
        echo "Network already exist for ${project}, so not creating any more"
fi