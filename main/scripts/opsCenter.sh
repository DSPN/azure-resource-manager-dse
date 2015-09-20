#!/bin/bash

USERNAME=$1
PASSWORD=$2
DATASTAX_USERNAME=$3
DATASTAX_PASSWORD=$4

installJava.sh

echo "Installing OpsCenter"
echo "deb http://debian.datastax.com/community stable main" | sudo tee -a /etc/apt/sources.list.d/datastax.community.list
curl -L http://debian.datastax.com/debian/repo_key | sudo apt-key add -
apt-get update
apt-get -y install opscenter

echo "Starting OpsCenter"
sudo service opscenterd start

echo "Waiting for OpsCenter to start..."
sleep 15

#configureOpsCenter.sh $USERNAME $PASSWORD $DATASTAX_USERNAME $DATASTAX_PASSWORD

