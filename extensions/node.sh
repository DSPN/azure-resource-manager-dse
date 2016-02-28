#!/usr/bin/env bash

cloud_type="azure"
data_center_name=$1
location=$2 #this is the location of the seed and OpsCenter, not necessarily of this node
uniqueString=$3

seed_node_dns_name="dc0vm0$uniqueString.$location.cloudapp.azure.com"

wget https://github.com/DSPN/install-datastax/archive/master.zip
apt-get -y install unzip
unzip master.zip
cd install-datastax-master/bin

./dse.sh $cloud_type $data_center_name $seed_node_dns_name
