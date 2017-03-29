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

# seeing racey fails of apt-get, add sleep/retry on error
apt-get -y install unzip
RET=$?
if [ $RET -ne 0 ]
then
  echo "ERROR: call to apt-get returned non-zero, exit code: $RET"
  echo "Sleeping 2m before retry..."
  sleep 2m
  apt-get -y install unzip
fi



wget https://github.com/DSPN/install-datastax-ubuntu/archive/master.zip
unzip master.zip
cd install-datastax-ubuntu-master/bin

./opscenter.sh $cloud_type $seed_node_dns_name
