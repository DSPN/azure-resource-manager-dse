#!/usr/bin/env bash

data_center_size=$1
opscfqdn=$2
data_center_name=$3
opscpw=$4
disksize=$5
cluster_name=$6

echo "Input to node.sh is:"
echo data_center_size $data_center_size
echo opscfqdn $opscfqdn
echo data_center_name $data_center_name
echo opscpw XXXXXX
echo disksize $disksize

# System setup/config
# Copied in from general install scripts
echo "Going to set the TCP keepalive for now."
sysctl -w net.ipv4.tcp_keepalive_time=120
echo "Going to set the TCP keepalive permanently across reboots."
echo "net.ipv4.tcp_keepalive_time = 120" >> /etc/sysctl.conf
echo "" >> /etc/sysctl.conf

# mount/format disk if needed
bash ./disk.sh $disksize

release="7.2.0"
tar -xvf $release.tar.gz

cd install-datastax-ubuntu-$release/bin/
# install extra packages, openjdk
./os/extra_packages.sh
./os/install_java.sh -o
./os/os.sh "azure"

# install az/azcopy
# az repo
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
    sudo tee /etc/apt/sources.list.d/azure-cli.list
curl -L https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
# azcopy repo
echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-xenial-prod/ xenial main" > azure.list
cp ./azure.list /etc/apt/sources.list.d/
apt-key adv --keyserver packages.microsoft.com --recv-keys EB3E94ADBE1229CF
# install
apt-get install apt-transport-https
apt-get update && sudo apt-get -y install azure-cli azcopy


# grabbing metadata after extra_packages.sh to ensure we have jq
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
--opscpw $opscpw \
--trys 120 \
--pause 10 \
--clustername $cluster_name \
--dcname $data_center_name \
--rack $rack \
--pubip $public_ip \
--privip $private_ip \
--nodeid $node_id
