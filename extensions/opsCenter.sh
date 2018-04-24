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

release="workshop"
wget https://github.com/DSPN/install-datastax-ubuntu/archive/$release.tar.gz
tar -xvf $release.tar.gz

cd install-datastax-ubuntu-$release/bin
# install extra packages
./os/extra_packages.sh

# Overide OpsC install default version if needed
export OPSC_VERSION='6.5.0'
ver='6.0.0'

./os/install_java.sh

#install opsc
./opscenter/install.sh 'azure'
./opscenter/start.sh
# Turn on https, set pw for opsc user admin
# Comment out for workshop
#./opscenter/set_opsc_pw_https.sh $opscpw
sleep 1m

# This config profile turns off auth, and overrides any other config settings
# created by other args except dsever
config="{ \"datastax-version\": \"6.0.0\", \"name\": \"test\", \"json\": { \"cassandra-yaml\": { \"authorizer\": \"AllowAllAuthorizer\", \"saved_caches_directory\": \"/data/cassandra/saved_caches\", \"data_file_directories\": [ \"/data/cassandra/data\" ], \"num_tokens\": 32, \"authenticator\": \"AllowAllAuthenticator\", \"endpoint_snitch\": \"org.apache.cassandra.locator.GossipingPropertyFileSnitch\", \"commitlog_directory\": \"/data/cassandra/commitlog\" }, \"dse-yaml\": { \"authorization_options\": { \"enabled\": true }, \"authentication_options\": { \"enabled\": true }, \"resource_manager_options\": { \"worker_options\": { \"workpools\": [ { \"memory\": \"0.25\", \"cores\": \"0.25\", \"name\": \"alwayson_sql\" } ] } }, \"alwayson_sql_options\": { \"enabled\": true } } }}"

echo "Calling setupCluster.py with the settings:"
echo opsc_ip 127.0.0.1s
echo cluster_name $cluster_name
echo username $username
echo password XXXXXX
echo repouser $repouser
echo repopw XXXXXX
echo config $config

./lcm/setupCluster.py \
--clustername $cluster_name \
--repouser $repouser \
--repopw $repopw \
--user $username \
--password $password \
--dbpasswd $dbpasswd \
--config "$config"

# trigger install
./lcm/triggerInstall.py \
--clustername $cluster_name \
--clustersize $nodecount


# Block execution while waiting for jobs to
# exit RUNNING/PENDING status
./lcm/waitForJobs.py
# set keyspaces to NetworkTopology / RF 3
sleep 30s
./lcm/alterKeyspaces.py