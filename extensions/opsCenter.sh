#!/usr/bin/env bash

username=$1
password=$2
opscpw=$3
dbpasswd=$4
nodecount=$5

echo "Input to opsCenter.sh is:"
echo username $username
echo password XXXXXX
echo opscpw YYYYYY
echo dbpasswd ZZZZZZZ
echo nodecount $nodecount

cluster_name="mycluster"

# repo creds
repouser='datastax@microsoft.com'
repopw='3A7vadPHbNT'

apt-get update
n=0
until [ $n -ge 20 ]
do
  apt-get -y install unzip python-pip jq  && break
  echo "apt-get try $n failed, sleeping 15s..."
  n=$[$n+1]
  sleep 15s
done

pip install requests

release="6.0.0"
wget https://github.com/DSPN/install-datastax-ubuntu/archive/$release.zip
unzip $release.zip
cd install-datastax-ubuntu-$release/bin

# Overide OpsC install default version if needed
export OPSC_VERSION='6.1.3'
ver='5.1.3'

./os/install_java.sh
# clean existing apt file
rm /etc/apt/sources.list.d/datastax.sources.list
#install opsc
./opscenter/install.sh 'azure'
./opscenter/start.sh
sleep 1m

echo "Calling setupCluster.py with the settings:"
echo opsc_ip 127.0.0.1
echo cluster_name $cluster_name
echo username $username
echo password XXXXXX
echo repouser $repouser
echo repopw XXXXXX

./lcm/setupCluster.py \
--opsc-ip 127.0.0.1 \
--clustername $cluster_name \
--repouser $repouser \
--repopw $repopw \
--dsever  $ver \
--user $username \
--password $password \
--datapath "/data/cassandra"

# trigger install
./lcm/triggerInstall.py \
--opsc-ip 127.0.0.1 \
--clustername $cluster_name \
--clustersize $nodecount \
--dclevel \
--dbpasswd $dbpasswd

# Block execution while waiting for jobs to
# exit RUNNING/PENDING status
./lcm/waitForJobs.py
# set keyspaces to NetworkTopology / RF 3
sleep 30s
./lcm/alterKeyspaces.py
# Turn on https, set pw for opsc user admin
./opscenter/set_opsc_pw_https.sh $opscpw
