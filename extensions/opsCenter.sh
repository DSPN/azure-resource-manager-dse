#!/usr/bin/env bash

location=$1
uniqueString=$2

seed_node_dns_name="dc0vm0$uniqueString.$location.cloudapp.azure.com"
seed_node_public_ip=$seed_node_dns_name

wget https://github.com/DSPN/install-datastax/archive/master.zip
apt-get -y install unzip
unzip master.zip
cd install-datastax-master/bin

./opscenter.sh $seed_node_public_ip
