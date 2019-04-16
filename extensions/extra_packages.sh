#!/usr/bin/env bash

# install extra packages
echo "---> install_java - dealing with apt.daily"
killall -9 apt apt-get apt-key
#
rm /var/lib/dpkg/lock
rm /var/lib/apt/lists/lock
rm /var/cache/apt/archives/lock
#
#dpkg --configure -a &
#dpkg_process_id=$!
#echo "dpkg_process_id $dpkg_process_id"

systemctl stop apt-daily.service
systemctl kill --kill-who=all apt-daily.service
echo "<--- install_java - apt.daily dealt with"


apt-get update
apt-get -y install zip unzip python-pip jq sysstat

# install requests pip pacakge
pip install requests
