#!/usr/bin/env bash

# install extra packages
echo -e "Checking if apt/dpkg running, start: $(date +%r)"
while ps -A | grep -e apt -e dpkg >/dev/null 2>&1; do sleep 10s; done;
echo -e "No other procs: $(date +%r)"

apt-get update
apt-get -y install zip unzip python-pip jq sysstat

# install requests pip pacakge
pip install requests
