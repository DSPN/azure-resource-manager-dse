#!/bin/bash
# This script installs OpenJDK and gets a VM ready so DataStax OpsCenter can perform an install on it.

echo "Installing Java"
apt-get -y install default-jre

echo "Partitioning and formatting all attached data disks"
bash vm-disk-utils-0.1.sh

echo "Modifying permissions"
chmod 777 /mnt
chmod 777 /datadisks

