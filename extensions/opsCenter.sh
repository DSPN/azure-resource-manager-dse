#!/usr/bin/env bash

cloud_type="azure"
location=$1 #this is the location of the seed, not necessarily of this node
unique_string=$2

seed_node_dns_name="dc0vm0$unique_string.$location.cloudapp.azure.com"

wget https://github.com/DSPN/install-datastax/archive/master.zip
apt-get -y install unzip
unzip master.zip
cd install-datastax-master/bin

./opscenter.sh $cloud_type $seed_node_dns_name
