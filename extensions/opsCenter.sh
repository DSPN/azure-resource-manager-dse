#!/usr/bin/env bash

username=$1
password=$2
opscpw=$3

echo "Input to node.sh is:"
echo username $username
echo password XXXXXX
echo opscpw YYYYYY

public_ip=`curl --retry 10 icanhazip.com`
cluster_name="mycluster"

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

release="dev"
wget https://github.com/DSPN/install-datastax-ubuntu/archive/$release.zip
unzip $release.zip
cd install-datastax-ubuntu-$release/bin

# Overide OpsC install default version if needed
export OPSC_VERSION='6.1.2'
ver='5.1.3'

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

# Block execution while waiting for jobs to
# exit RUNNING/PENDING status
./lcm/waitForJobs.py
# set keyspaces to NetworkTopology / RF 3
./lcm/alterKeyspaces.py
# Turn on https, set pw for opsc user admin
./opscenter/set_opsc_pw_https.sh $opscpw
