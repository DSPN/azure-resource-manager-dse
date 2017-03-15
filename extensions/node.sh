#!/usr/bin/env bash

data_center_size=$1
unique_string=$2
data_center_name=$3
opscenter_location=$4
dbpasswd=$5
#--dbpasswd , { "Ref" : "DBPassword"}

echo "Input to node.sh is:"
echo unique_string $unique_string
echo data_center_name $data_center_name
echo opscenter_location $opscenter_location

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

opscenter_dns_name="opscenter$unique_string.$opscenter_location.cloudapp.azure.com"
cluster_name="mycluster"
public_ip=`curl --retry 10 icanhazip.com`
private_ip=`echo $(hostname -I)`
node_id=$private_ip

fault_domain=$(curl --max-time 50000 --retry 12 --retry-delay 50000 http://169.254.169.254/metadata/v1/InstanceInfo -s -S | sed -e 's/.*"FD":"\([^"]*\)".*/\1/')
rack=FD$fault_domain

echo "Calling addNode.py with the settings:"
echo opscenter_dns_name $opscenter_dns_name
echo cluster_name $cluster_name
echo data_center_size $data_center_size
echo data_center_name $data_center_name
echo rack $rack
echo public_ip $public_ip
echo private_ip $private_ip
echo node_id $node_id

apt-get update
apt-get -y install unzip python-pip
pip install requests

#cd /
wget https://github.com/DSPN/install-datastax-ubuntu/archive/master.zip
unzip master.zip
cd install-datastax-ubuntu-master/bin/lcm

./addNode.py \
--opsc-ip $opscenter_dns_name \
--clustername $cluster_name \
--dcsize $data_center_size \
--dcname $data_center_name \
--rack $rack \
--pubip $public_ip \
--privip $private_ip \
--nodeid $node_id \
--dbpasswd $dbpasswd
