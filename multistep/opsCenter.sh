#!/usr/bin/env bash

username=$1
password=$2
cluster_name=$3

echo "Input to opsCenter.sh is:"
echo username $username
echo password XXXXXX
echo cluster_name $cluster_name

##### Turn off the firewall
service firewalld stop
chkconfig firewalld off

##### Install required OS packages
yum makecache fast
yum -y install unzip wget
wget wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -ivh epel-release-latest-7.noarch.rpm
yum -y install python-pip
pip install requests

# repo creds
repouser='datastax@microsoft.com'
repopw='3A7vadPHbNT'

release="master"
wget https://github.com/DSPN/install-datastax-redhat/archive/$release.tar.gz
tar -xvf $release.tar.gz

cd install-datastax-redhat-$release/bin

./os/install_java.sh

#install opsc
./opscenter/install.sh 'azure'
./opscenter/start.sh
cd ../..
echo "Sleeping 1m..."
sleep 1m

# Overide OpsC install default version if needed
export OPSC_VERSION='6.1.5'
ver='5.1.5'

release="6.0.3"
wget https://github.com/DSPN/install-datastax-ubuntu/archive/$release.tar.gz
tar -xvf $release.tar.gz

cd install-datastax-ubuntu-$release/bin

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
