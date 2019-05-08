#!/usr/bin/env bash
export DEBIAN_FRONTEND=noninteractive

# install extra packages
echo -e "Checking if apt/dpkg running, start: $(date +%r)"
echo "---> install extrapkg - dealing with apt.daily"
pkill -9  apt
killall -9 apt apt-get apt-key
#
rm /var/lib/dpkg/lock
rm /var/lib/apt/lists/lock
rm /var/cache/apt/archives/lock
#
#dpkg --configure -a &
#dpkg_process_id=$!
#echo "dpkg_process_id $dpkg_process_id"
#echo -e "No other procs: $(date +%r)"


systemctl stop apt-daily.service
systemctl kill --kill-who=all apt-daily.service
echo "---> install extrapkg -  apt.daily dealt with"

# wait until `apt-get updated` has been killed
#while ! (systemctl list-units --all apt-daily.service | fgrep -q dead)
#do
#  sleep 1;
#done

apt-get update
apt-get -y install zip unzip python-pip jq sysstat

# install requests pip pacakge
pip install requests
