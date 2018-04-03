#!/usr/bin/env bash

data_center_size=$1
opscfqdn=$2
data_center_name=$3
opscpw=$4

echo "Input to node.sh is:"
echo data_center_size $data_center_size
echo opscfqdn $opscfqdn
echo data_center_name $data_center_name
echo opscpw XXXXXX

# System setup/config
# Copied in from general install scripts
echo "Going to set the TCP keepalive for now."
sysctl -w net.ipv4.tcp_keepalive_time=120
echo "Going to set the TCP keepalive permanently across reboots."
echo "net.ipv4.tcp_keepalive_time = 120" >> /etc/sysctl.conf
echo "" >> /etc/sysctl.conf

# mount data disk
cp /etc/fstab /etc/fstab.bak
# add C* data disk
mkfs -t ext4 /dev/sdc
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

cluster_name="mycluster"
public_ip=`curl --retry 10 icanhazip.com`
private_ip=`echo $(hostname -I)`
node_id=$private_ip

fault_domain=$(curl --max-time 50000 --retry 12 --retry-delay 50000 http://169.254.169.254/metadata/v1/InstanceInfo -s -S | sed -e 's/.*"FD":"\([^"]*\)".*/\1/')
rack=FD$fault_domain

release="workshop"
wget https://github.com/DSPN/install-datastax-ubuntu/archive/$release.tar.gz
tar -xvf $release.tar.gz

cd install-datastax-ubuntu-$release/bin/
# install extra packages
./os/extra_packages.sh

echo "Calling addNode.py with the settings:"
echo opscfqdn $opscfqdn
echo opscpw XXXXXX
echo cluster_name $cluster_name
echo data_center_size $data_center_size
echo data_center_name $data_center_name
echo rack $rack
echo public_ip $public_ip
echo private_ip $private_ip
echo node_id $node_id

./lcm/addNode.py \
--opsc-ip $opscfqdn \
--clustername $cluster_name \
--dcname $data_center_name \
--rack $rack \
--pubip $public_ip \
--privip $private_ip \
--nodeid $node_id

# block and wait for jobs before running any workshop setup
./lcm/waitForJobs.py --opsc-ip $opscfqdn
sleep 30s

if [ $HOSTNAME == 'dc0vm0' ]
then
  echo "node.sh run on dc0vm0, calling workshop setup..."
  cd ../../
  release='azure'
  wget https://github.com/cpoczatek/dse-halfday-workshop/archive/$release.tar.gz
  tar -xvf $release.tar.gz
  cd dse-halfday-workshop-$release/
  ./startup
fi
