#!/usr/bin/env bash

username=$1
password=$2
cluster_name=$3

echo "Input to opsCenter.sh is:"
echo username $username
echo password XXXXXX
echo cluster_name $cluster_name

# repo creds
repouser='datastax@microsoft.com'
repopw='3A7vadPHbNT'

release="6.0.3"
wget https://github.com/DSPN/install-datastax-ubuntu/archive/$release.tar.gz
tar -xvf $release.tar.gz

cd install-datastax-ubuntu-$release/bin
# install extra packages
./os/extra_packages.sh

# Overide OpsC install default version if needed
export OPSC_VERSION='6.1.5'
ver='5.1.5'

./os/install_java.sh

#install opsc
./opscenter/install.sh 'azure'
./opscenter/start.sh
sleep 1m

echo "Calling setupCluster.py with the settings:"
echo opsc_ip 127.0.0.1
echo cluster_name $cluster_name
echo username $username
echo password XXXXXX
echo repouser $repouser
echo repopw XXXXXX

./lcm/setupCluster.py \
--opsc-ip 127.0.0.1 \
--clustername $cluster_name \
--repouser $repouser \
--repopw $repopw \
--dsever  $ver \
--user $username \
--password $password \
--datapath "/data/cassandra"
