#!/usr/bin/env bash

username=$1
password=$2

echo "Input to node.sh is:"
echo username $username
echo password $password

public_ip=`curl --retry 10 icanhazip.com`
cluster_name="mycluster"

echo "Calling setupCluster.py with the settings:"
echo public_ip $public_ip
echo cluster_name $cluster_name
echo username $username
echo password $password

apt-get update
apt-get -y install unzip python-pip
RET=$?
if [ $RET -ne 0 ]
then
  echo "ERROR: call to apt-get returned non-zero, exit code: $RET"
  echo "Sleeping 2m before retry..."
  sleep 1m
  apt-get -y install unzip python-pip
fi

pip install requests

cd /tmp
wget https://github.com/DSPN/install-datastax-ubuntu/archive/5.5.1.zip
unzip 5.5.1.zip
cd install-datastax-ubuntu-5.5.1/bin

# Overide install default version
export OPSC_VERSION='6.0.8'

./os/install_java.sh
./opscenter/install.sh
./opscenter/start.sh
sleep 1m
./lcm/setupCluster.py \
--opsc-ip $public_ip \
--clustername $cluster_name \
--user $username \
--password $password \
--datapath "/mnt/cassandra"
