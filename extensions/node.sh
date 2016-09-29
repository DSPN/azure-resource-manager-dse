#!/usr/bin/env bash

cloud_type="azure"
seed_node_location=$1
unique_string=$2
data_center_name=$3
opscenter_location=$4

echo "Input to node.sh is:"
echo cloud_type $cloud_type
echo seed_node_location $seed_node_location
echo unique_string $unique_string
echo opscenter_location $opscenter_location

seed_node_dns_name="dc0vm0$unique_string.$seed_node_location.cloudapp.azure.com"
opscenter_dns_name="opscenter$unique_string.$opscenter_location.cloudapp.azure.com"

echo "Calling dse.sh with the settings:"
echo cloud_type $cloud_type
echo seed_node_dns_name $seed_node_dns_name
echo data_center_name $data_center_name
echo opscenter_dns_name $opscenter_dns_name
echo dse_version $dse_version

apt-get -y install unzip

wget https://github.com/DSPN/install-datastax-ubuntu/archive/master.zip
unzip master.zip
cd install-datastax-ubuntu-master/bin

./dse.sh $cloud_type $seed_node_dns_name $data_center_name $opscenter_dns_name
