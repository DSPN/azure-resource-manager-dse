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

pkill -9  apt
pkill -9  dpkg
killall -9 apt apt-get apt-key
#
rm /var/lib/dpkg/lock
rm /var/lib/apt/lists/lock
rm /var/cache/apt/archives/lock
#
systemctl stop apt-daily.timer
systemctl stop apt-daily.service
systemctl kill --kill-who=all apt-daily.service

release="7.1.0"
#tar -xvf $release.tar.gz
#tar -xvf dpkgup7.2.0
#tar -xvf dse6.7
#mv DSPN-install-datastax-ubuntu* install-datastax-ubuntu-$release
# DSPN-install-datastax-ubuntu-7.2.0-1-gd063320.tar.gz
#wget https://github.com/DSPN/install-datastax-ubuntu/archive/$release.tar.gz
wget https://github.com/DSPN/install-datastax-ubuntu/tarball/dpkgup7.2.0 
tar -xvf dpkgup7.2.0
mv DSPN-install-datastax-ubuntu* install-datastax-ubuntu-$release
#tar -xvf $release.tar.gz

cd install-datastax-ubuntu-$release/bin/
# install extra packages, openjdk
./os/extra_packages.sh
./os/install_java.sh -o
ln -s /usr/lib/jvm/java-8-openjdk-amd64/bin/jps /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/jps
ls -l /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/jps

# grabbing metadata after extra_packages.sh to ensure we have jq
cluster_name="mycluster"
private_ip=`echo $(hostname -I)`
node_id=$private_ip
public_ip=$(curl --max-time 200 --retry 12 --retry-delay 5 -sS -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2017-04-02" | \
jq .network.interface[0].ipv4.ipAddress[0].publicIpAddress | \
tr -d '"')
if [ -z "$public_ip" ]; then
    echo "public_ip doesn't exist, setting to private_ip"
    public_ip=$private_ip
fi

fault_domain=$(curl -sS --max-time 200 --retry 12 --retry-delay 5 -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2017-04-02" | \
jq .compute.platformFaultDomain | \
tr -d '"')
rack=FD$fault_domain

# override, use only priv ip
public_ip=$private_ip

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
--trys 120 \
--pause 10 \
--clustername $cluster_name \
--dcname $data_center_name \
--rack $rack \
--pubip $public_ip \
--privip $private_ip \
--nodeid $node_id



# block and wait for jobs before running any workshop setup
./lcm/waitForJobs.py --opsc-ip $opscfqdn
sleep 30s

# add aliases to /etc/hosts, could be a regex...
newname='node0'
if [ $HOSTNAME == 'dc0vm1' ]; then newname='node1'; fi
if [ $HOSTNAME == 'dc0vm2' ]; then newname='node1'; fi
echo -e "#added aliases\n127.0.0.1 $newname" >> /etc/hosts

if [ $HOSTNAME == 'dc0vm0' ]
then
  echo "node.sh run on dc0vm0, calling workshop setup in /tmp ..."

  cd /tmp
  git clone https://github.com/scotthds/dse-halfday-workshop.git
  cd dse-halfday-workshop/
  git checkout azure
  ./startup all
fi
