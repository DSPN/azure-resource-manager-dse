#!/usr/bin/env bash

data_center_size=$1
opscenter_ip=$2
data_center_name=$3
opscenter_location=$4
cluster_name=$5

echo "Input to node.sh is:"
echo data_center_size $data_center_size
echo opscenter_ip $opscenter_ip
echo data_center_name $data_center_name
echo opscenter_location $opscenter_location
echo dbpasswd XXXXX
echo cluster_name $cluster_name

##### Turn off the firewall
service firewalld stop
chkconfig firewalld off

##### Install required OS packages
yum makecache fast
yum -y install unzip wget
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -ivh epel-release-latest-7.noarch.rpm
yum -y install python-pip
pip install requests

# mount data disk
cp /etc/fstab /etc/fstab.bak
# add C* data disk
mkfs -F -t ext4 /dev/sdc
uuid=$(blkid /dev/sdc -sUUID -ovalue)
mkdir -p /data/cassandra
echo "# Cassandra data mount, template auto-generated." >> /etc/fstab
echo "UUID=$uuid       /data/cassandra   ext4    defaults,nofail        1       2" >> /etc/fstab
mount -a
mkdir -p /data/cassandra/data
mkdir -p /data/cassandra/commitlog
mkdir -p /data/cassandra/saved_caches
useradd cassandra
chown -R cassandra:cassandra /data/cassandra

private_ip=`echo $(hostname -I)`
public_ip=`curl --retry 10 icanhazip.com`
node_id=$private_ip

fault_domain=$(curl --max-time 50000 --retry 12 --retry-delay 50000 http://169.254.169.254/metadata/v1/InstanceInfo -s -S | sed -e 's/.*"FD":"\([^"]*\)".*/\1/')
rack=FD$fault_domain

release="config"
wget https://github.com/DSPN/install-datastax-ubuntu/archive/$release.tar.gz
tar -xvf $release.tar.gz

cd install-datastax-ubuntu-$release/bin/

echo "Calling addNode.py with the settings:"
echo opscenter_ip $opscenter_ip
echo cluster_name $cluster_name
echo data_center_size $data_center_size
echo data_center_name $data_center_name
echo rack $rack
echo public_ip $public_ip
echo private_ip $private_ip
echo node_id $node_id


./lcm/addNode.py \
--opsc-ip $opscenter_ip \
--clustername $cluster_name \
--dcname $data_center_name \
--rack $rack \
--pubip $public_ip \
--privip $private_ip \
--nodeid $node_id \
