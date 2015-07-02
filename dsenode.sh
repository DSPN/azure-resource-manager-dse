#!/bin/bash

# Description: This script prepares an Ubuntu VM image for DataStax OpsCenter node cluster installation and configuration

# Partition and format all attached data disks
bash vm-disk-utils-0.1.sh

log()
{
    echo "$1" >> /var/log/azure/dsenode.sh.log
}

# Add hostnames to /etc/hosts
grep -q "${HOSTNAME}" /etc/hosts
if [ $? == 0 ];
then
  log "${HOSTNAME} found in /etc/hosts"
else
  log "${HOSTNAME} not found in /etc/hosts, going to add it..."
  echo "127.0.0.1 ${HOSTNAME}" >> /etc/hosts
fi

# Install Java
add-apt-repository -y ppa:webupd8team/java
apt-get -y update 
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
apt-get -y install oracle-java8-installer

chmod 777 /mnt
chmod 777 /datadisks

