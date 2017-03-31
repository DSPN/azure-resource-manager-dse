#!/usr/bin/env bash

username=$1
password=$2
cluster_name=$3

echo "Input to node.sh is:"
echo username $username
echo password XXXXX
echo

public_ip=`curl --retry 10 icanhazip.com`

echo "Calling setupCluster.py with the settings:"
echo public_ip $public_ip
echo cluster_name $cluster_name
echo username $username
echo password XXXXXX

apt-get update
apt-get -y install unzip python-pip
pip install requests

cd /
wget https://github.com/DSPN/install-datastax-ubuntu/archive/dev.zip
unzip dev.zip
cd install-datastax-ubuntu-dev/bin/

# Overide install default version
export OPSC_VERSION='6.0.8'

./os/install_java.sh
./opscenter/install.sh
./opscenter/start.sh

#KLUDGE! Force un-parameterized changes
sed -ie 's/5.0.7/5.0.5/g' ./lcm/setupCluster.py

sleep 1m
./lcm/setupCluster.py \
--opsc-ip $public_ip \
--clustername $cluster_name \
--user $username \
--password $password \
--datapath "/mnt/cassandra"
