#!/bin/bash

bash installJava.sh

echo "Installing OpsCenter"
echo "deb http://debian.datastax.com/community stable main" | sudo tee -a /etc/apt/sources.list.d/datastax.community.list
curl -L http://debian.datastax.com/debian/repo_key | sudo apt-key add -
apt-get update
apt-get -y install opscenter=5.2.4

bash set_reported_interface.sh

echo "Starting OpsCenter"
sudo service opscenterd start

echo "Waiting for OpsCenter to start..."
sleep 15

echo "Python script needs sshpass to determine local IPs."
apt-get -y install sshpass

echo "Generating a provision.json file"
python opsCenter.py $1 $2 $3 $4 $5 $6 $7

echo "Provisioning a new cluster using provision.json"
curl --insecure -H "Accept: application/json" -X POST http://127.0.0.1:8888/provision -d @provision.json
