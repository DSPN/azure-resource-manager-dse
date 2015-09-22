#!/bin/bash

# save our b64 encoded json parameters for later
echo $1 > b64input

bash installJava.sh

echo "Installing OpsCenter"
echo "deb http://debian.datastax.com/community stable main" | sudo tee -a /etc/apt/sources.list.d/datastax.community.list
curl -L http://debian.datastax.com/debian/repo_key | sudo apt-key add -
apt-get update
apt-get -y install opscenter=5.2.1

echo "Starting OpsCenter"
sudo service opscenterd start

echo "Waiting for OpsCenter to start..."
sleep 15

echo "Generating a provision.json file"
python opsCenter.py $1

echo "Provisioning a new cluster using provision.json"
curl --insecure -H "Accept: application/json" -X POST http://127.0.0.1:8888/provision -d @provision.json

