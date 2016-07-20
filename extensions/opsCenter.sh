#!/usr/bin/env bash

cloud_type="azure"
seed_node_location=$1
unique_string=$2

echo "Input to node.sh is:"
echo cloud_type $cloud_type
echo seed_node_location $seed_node_location
echo unique_string $unique_string

seed_node_dns_name="dc0vm0$unique_string.$seed_node_location.cloudapp.azure.com"

echo "Calling opscenter.sh with the settings:"
echo cloud_type $cloud_type
echo seed_node_dns_name $seed_node_dns_name

#wget https://github.com/DSPN/install-datastax/archive/1.1.zip
wget https://github.com/DSPN/install-datastax/archive/master.zip

apt-get -y install unzip

#unzip 1.1.zip
unzip master.zip

#cd install-datastax-1.1/bin
cd master/bin

./opscenter.sh $cloud_type $seed_node_dns_name
