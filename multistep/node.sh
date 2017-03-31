#!/usr/bin/env bash

data_center_size=$1
opscenter_ip=$2
data_center_name=$3
opscenter_location=$4
dbpasswd=$5
cluster_name=$6

echo "Input to node.sh is:"
echo data_center_size $data_center_size
echo opscenter_ip $opscenter_ip
echo data_center_name $data_center_name
echo opscenter_location $opscenter_location
echo dbpasswd XXXXX
echo cluster_name $cluster_name

# System setup/config
# Copied in from general install scripts
echo "Going to set the TCP keepalive for now."
sysctl -w net.ipv4.tcp_keepalive_time=120
echo "Going to set the TCP keepalive permanently across reboots."
echo "net.ipv4.tcp_keepalive_time = 120" >> /etc/sysctl.conf
echo "" >> /etc/sysctl.conf

# Move tmp disk mount pt and mount data disk
cp /etc/fstab /etc/fstab.bak
# tmp disk mounted at /mnt by default, moving to /mnt/tmp
umount /mnt
mkdir /mnt/tmp
sed -ie 's/mnt/mnt\/tmp/g' /etc/fstab
# add C* data disk
mkfs -t ext4 /dev/sdc
mkdir /mnt/cassandra
echo "# Cassandra data mount, template auto-generated." >> /etc/fstab
echo "/dev/sdc       /mnt/cassandra   ext4    defaults,nofail        0       2" >> /etc/fstab
mount -a
mkdir /mnt/cassandra/data
mkdir /mnt/cassandra/commitlog
mkdir /mnt/cassandra/saved_caches
useradd cassandra
chown -R cassandra:cassandra /mnt/cassandra

# Ignoring public_ip
# public_ip=`curl --retry 10 icanhazip.com`
private_ip=`echo $(hostname -I)`
node_id=$private_ip

fault_domain=$(curl --max-time 50000 --retry 12 --retry-delay 50000 http://169.254.169.254/metadata/v1/InstanceInfo -s -S | sed -e 's/.*"FD":"\([^"]*\)".*/\1/')
rack=FD$fault_domain

echo "Calling addNode.py with the settings:"
echo opscenter_ip $opscenter_ip
echo cluster_name $cluster_name
echo data_center_size $data_center_size
echo data_center_name $data_center_name
echo rack $rack
echo public_ip [Ignored] $public_ip
echo private_ip $private_ip
echo node_id $node_id

apt-get update
apt-get -y install unzip python-pip
pip install requests

#cd /
wget https://github.com/DSPN/install-datastax-ubuntu/archive/dev.zip
unzip dev.zip
cd install-datastax-ubuntu-dev/bin/lcm

#KLUDGE! Force un-parameterized changes
sed -ie 's/\"graph-enabled\": True/\"graph-enabled\": False/g' ./utilLCM.py
sed -ie 's/\"spark-enabled\": True/\"spark-enabled\": False/g' ./utilLCM.py
sed -ie 's/\"solr-enabled\": True/\"solr-enabled\": False/g' ./utilLCM.py

./addNode.py \
--opsc-ip $opscenter_ip \
--clustername $cluster_name \
--dcsize $data_center_size \
--dcname $data_center_name \
--rack $rack \
--pubip $private_ip \
--privip $private_ip \
--nodeid $node_id \
--dbpasswd $dbpasswd
