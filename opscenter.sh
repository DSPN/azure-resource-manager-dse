#!/bin/bash
# This script installs and configures DataStax OpsCenter.  It then deploys a DataStax cluster using OpsCenter.

log()
{
    echo "$1" >> /var/log/azure/opscenter.sh.log
}

#log "Adding hostname to /etc/hosts"
#echo "127.0.0.1 ${HOSTNAME}" >> /etc/hosts

log "Setting default parameters"
CLUSTER_NAME="Test Cluster"
DSE_VERSION="4.7.0"

while getopts :n:u:p:e:v:U:P optname; do
  log "Option $optname set with value ${OPTARG}"
  case $optname in
    n)
      CLUSTER_NAME=${OPTARG}
      ;;
    u) 
      # Cluster node admin user that OpsCenter uses for cluster provisioning
      ADMIN_USER=${OPTARG}
      ;;
    p)
      # Cluster node password that OpsCenter uses for cluster provisioning
      ADMIN_PASSWORD=${OPTARG}
      ;;
    e)
      # List of successive cluster IP addresses represented as the starting address and a count used to increment the last octet (10.0.0.5-3)
      DSE_ENDPOINTS=${OPTARG}
      ;;
    v) 
      # DSE Version
      DSE_VERSION=${OPTARG}
      ;;
    U)
      # DataStax download site username 
      DSE_USERNAME=${OPTARG}
      ;;
    P)
      # DataStax download site password
      DSE_PASSWORD=${OPTARG}
      ;;
    \?)
      log "Option -${BOLD}$OPTARG${NORM} is an invalid.  Exiting."
      exit 2
      ;;
  esac
done

log "Installing Java"
add-apt-repository -y ppa:webupd8team/java
apt-get -y update 
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
apt-get -y install oracle-java8-installer
 
log "Installing OpsCenter"
echo "deb http://debian.datastax.com/community stable main" | sudo tee -a /etc/apt/sources.list.d/datastax.community.list
curl -L http://debian.datastax.com/debian/repo_key | sudo apt-key add -
apt-get update
apt-get install opscenter

log "Starting OpsCenter"
sudo service opscenterd start

#############################################################################
#### Now that we have OpsCenter installed, let's configure our cluster. #####
#############################################################################

# Expand a list of successive ip range and filter my local local ip from the list
# This increments the last octet of an IP start range using a defined value
# 10.0.0.5-3 would be converted to "10.0.0.5 10.0.0.6 10.0.0.7"
expand_ip_range() {
  IFS='-' read -a IP_RANGE <<< "$1"
  BASE_IP=`echo ${IP_RANGE[0]} | cut -d"." -f1-3`
  LAST_OCTET=`echo ${IP_RANGE[0]} | cut -d"." -f4-4`

  # Get the IP Addresses on this machine
  declare -a MY_IPS=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'`
  declare -a EXPAND_STATICIP_RANGE_RESULTS=()

  for (( n=LAST_OCTET; n<("${IP_RANGE[1]}"+LAST_OCTET) ; n++))
  do
    HOST="${BASE_IP}.${n}"
    if ! [[ "${MY_IPS[@]}" =~ "${HOST}" ]]; then
      EXPAND_STATICIP_RANGE_RESULTS+=($HOST)
    fi
  done
  log "EXPAND_STATICIP_RANGE_RESULTS: ${EXPAND_STATICIP_RANGE_RESULTS[@]}"
}

# Convert the DSE endpoint range to a list for the provisioning configuration
log "DSE_ENDPOINTS are: $DSE_ENDPOINTS"
NODE_IP_LIST=$(expand_ip_range "$DSE_ENDPOINTS")

get_node_fingerprints() {
  TR=($1)

  ACCEPTED_FINGERPRINTS=""
  for HOST in "${TR[@]}";
  do
    ssh-keyscan -p 22 -t rsa "$HOST" > /tmp/tmpsshkeyhost.pub
    HOSTKEY=$(ssh-keygen -lf /tmp/tmpsshkeyhost.pub)

    HOSTKEY=`echo ${HOSTKEY} | cut -d" " -f1-2`
    HOSTKEY+=" (RSA)"
    ACCEPTED_FINGERPRINTS+="\"$HOST\": \"$HOSTKEY\","
  done
  ACCEPTED_FINGERPRINTS="${ACCEPTED_FINGERPRINTS%?}"
  log "ACCEPTED_FINGERPRINTS: $ACCEPTED_FINGERPRINTS"
}

NODE_CONFIG_LIST="\"${NODE_IP_LIST// /\",\"}\""
ACCEPTED_FINGERPRINTS=$(get_node_fingerprints "$NODE_IP_LIST")

# Create node provisioning document
sudo tee provision.json > /dev/null <<EOF
{
    "cassandra_config": {
        "authenticator": "org.apache.cassandra.auth.AllowAllAuthenticator",
        "auto_bootstrap": false,
        "auto_snapshot": true,
        "start_native_transport": true,
        "cluster_name": "${CLUSTER_NAME}",
        "column_index_size_in_kb": 64,
        "commitlog_directory": "/mnt/cassandra/commitlog",
        "commitlog_sync": "periodic",
        "commitlog_sync_period_in_ms": 10000,
        "compaction_throughput_mb_per_sec": 16,
        "concurrent_reads": 32,
        "concurrent_writes": 32,
        "data_file_directories": [
            "/mnt/cassandra/data"
        ],
        "dynamic_snitch_badness_threshold": 0.1,
        "dynamic_snitch_reset_interval_in_ms": 600000,
        "dynamic_snitch_update_interval_in_ms": 100,
        "server_encryption_options": {
            "internode_encryption": "none",
            "keystore": "conf/.keystore",
            "keystore_password": "cassandra",
            "truststore": "conf/.truststore",
            "truststore_password": "cassandra"
        },
        "endpoint_snitch": "com.datastax.bdp.snitch.DseSimpleSnitch",
        "hinted_handoff_enabled": true,
        "incremental_backups": false,
        "index_interval": 128,
        "initial_token": null,
        "key_cache_save_period": 14400,
        "key_cache_size_in_mb": null,
        "max_hint_window_in_ms": 3600000,
        "partitioner": "org.apache.cassandra.dht.RandomPartitioner",
        "request_scheduler": "org.apache.cassandra.scheduler.NoScheduler",
        "row_cache_save_period": 0,
        "row_cache_size_in_mb": 0,
        "rpc_keepalive": true,
        "rpc_port": 9160,
        "rpc_server_type": "sync",
        "saved_caches_directory": "/mnt/cassandra/saved_caches",
        "snapshot_before_compaction": false,
        "ssl_storage_port": 7001,
        "storage_port": 7000,
        "thrift_framed_transport_size_in_mb": 15,
        "thrift_max_message_length_in_mb": 16,
        "trickle_fsync": false,
        "trickle_fsync_interval_in_kb": 10240
    },
    "install_params": {
        "username": "${ADMIN_USER}",
        "password": "${ADMIN_PASSWORD}",
        "package": "dse",
        "version": "${DSE_VERSION}",
        "repo-user": "${DSE_USERNAME}",
        "repo-password": "${DSE_PASSWORD}"
    },
    "nodes": [
        ${NODE_CONFIG_LIST}
    ],
    "accepted_fingerprints": {
        ${ACCEPTED_FINGERPRINTS}
    }
}
EOF

# Write this somewhere we can look at it later for debugging
cat provision.json > /var/log/azure/provision.json

# Give OpsCenter a bit to come up and then provision a new cluster
sleep 15
log "Calling OpsCenter with curl."
curl -H "Accept: application/json" -X POST http://127.0.0.1:8888/provision -d @provision.json

