#!/bin/bash
# This script gets a VM ready so DataStax OpsCenter can perform an install on it.

# Partition and format all attached data disks
bash vm-disk-utils-0.1.sh

log()
{
    echo "$1" >> /var/log/azure/dsenode.sh.log
}

#log "Adding hostname to /etc/hosts"
#echo "127.0.0.1 ${HOSTNAME}" >> /etc/hosts

log "Installing Java"
add-apt-repository -y ppa:webupd8team/java
apt-get -y update 
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
apt-get -y install oracle-java8-installer

log "Modifying permissions"
chmod 777 /mnt
chmod 777 /datadisks

