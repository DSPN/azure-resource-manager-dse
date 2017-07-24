#!/usr/bin/env bash

username=$1
password=$2
cluster_name=$3

echo "Input to opsCenter.sh is:"
echo username $username
echo password XXXXX
echo cluster_name

#public_ip=`curl --retry 10 icanhazip.com`
public_ip='127.0.0.1'

echo "Calling setupCluster.py with the settings:"
echo public_ip $public_ip
echo cluster_name $cluster_name
echo username $username
echo password XXXXXX

apt-get update
n=0
until [ $n -ge 8 ]
do
  apt-get -y install unzip python-pip jq  && break
  echo "apt-get try $n failed, sleeping..."
  n=$[$n+1]
  sleep 15s
done

pip install requests

release="5.5.4"
wget https://github.com/DSPN/install-datastax-ubuntu/archive/$release.zip
unzip $release.zip
cd install-datastax-ubuntu-$release/bin

# Overide OpsC install default version if needed
export OPSC_VERSION='6.1.1'
ver='5.1.1'

./os/install_java.sh
./opscenter/install.sh
./opscenter/start.sh
sleep 1m
./lcm/setupCluster.py \
--opsc-ip $public_ip \
--clustername $cluster_name \
--dsever  $ver \
--user $username \
--password $password \
--datapath "/data/cassandra"
