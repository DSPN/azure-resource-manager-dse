#!/bin/bash
# This script installs DataStax OpsCenter.  It then deploys a DataStax Enterprise cluster using OpsCenter.

DSE_VERSION="4.7.1"

while getopts ":n:u:p:e:v:c:U:P:" opt; do
  echo "Option $opt set with value $OPTARG"
  case $opt in
    n)
      CLUSTER_NAME=$OPTARG
      ;;
    u) 
      # Cluster node admin user that OpsCenter uses for cluster provisioning
      ADMIN_USERNAME=$OPTARG
      ;;
    p)
      # Cluster node password that OpsCenter uses for cluster provisioning
      ADMIN_PASSWORD=$OPTARG
      ;;
    e)
      # List of successive cluster IP addresses represented as the starting address and a count used to increment the last octet (for example 10.0.0.5-3)
      NODE_IP_RANGE=$OPTARG
      ;;
    c)
      # Number of successive cluster IP addresses sent for NODE_IP_RANGE
      NUM_NODE_IP_RANGE=$OPTARG
      ;;
    v) 
      DSE_VERSION=$OPTARG
      ;;
    U)
      # DataStax download site username 
      DATASTAX_USERNAME=$OPTARG
      ;;
    P)
      # DataStax download site password
      DATASTAX_PASSWORD=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG"
      ;;
  esac
done

IFS=';' read -a IP_LIST <<< "${NODE_IP_RANGE}"
IFS='-' read -a IP_RANGE <<< "${IP_LIST[0]}"
NODE_COUNT="${IP_RANGE[1]}"

echo "127.0.0.1 ${HOSTNAME}" >> /etc/hosts
echo "127.0.0.1 localhost.localdomain localhost" >> /etc/hosts
echo "10.0.0.5  opcvm" >> /etc/hosts
echo '*/1 * * * * sudo service walinuxagent start' > cronjob
crontab cronjob
for (( i=0; i<$NUM_NODE_IP_RANGE ; i++))
do
    for (( j=0; j<$NODE_COUNT ; j++))
    do
        echo "10.0.$i.$(expr $j + 6)  dc${i}vm${j}" >> /etc/hosts
    done
done
 
echo "Installing OpsCenter"
echo "deb http://debian.datastax.com/community stable main" | sudo tee -a /etc/apt/sources.list.d/datastax.community.list
curl -L http://debian.datastax.com/debian/repo_key | sudo apt-key add -
apt-get update
apt-get install opscenter

# Enable authentication in /etc/opscenter/opscenterd.conf
sed -i '/^\[authentication\]$/,/^\[/ s/^enabled = False/enabled = True/' /etc/opscenter/opscenterd.conf

# Enable SSL - uncomment webserver SSL settings and leave them set to the default
sed -i '/^\[webserver\]$/,/^\[/ s/^#ssl_keyfile/ssl_keyfile/' /etc/opscenter/opscenterd.conf
sed -i '/^\[webserver\]$/,/^\[/ s/^#ssl_certfile/ssl_certfile/' /etc/opscenter/opscenterd.conf
sed -i '/^\[webserver\]$/,/^\[/ s/^#ssl_port/ssl_port/' /etc/opscenter/opscenterd.conf

echo "Starting OpsCenter"
sudo service opscenterd start

#############################################################################
#### Now that we have OpsCenter installed, let's configure our cluster. #####
#############################################################################

# Expand an IP range. 10.0.0.5-2;10.0.1.5-2; would be converted to "10.0.0.5 10.0.0.6 10.0.1.5 10.0.1.6"
expand_ip_range() {
  IFS=';' read -a IP_LIST <<< "$1"

  for (( k=0; k<$2 ; k++))
  do
    IFS='-' read -a IP_RANGE <<< "${IP_LIST[${k}]}"
    BASE_IP=`echo ${IP_RANGE[0]} | cut -d"." -f1-3`
    LAST_OCTET=`echo ${IP_RANGE[0]} | cut -d"." -f4-4`

    for (( n=LAST_OCTET; n<("${IP_RANGE[1]}"+LAST_OCTET) ; n++))
    do
      HOST="${BASE_IP}.${n}"
      EXPAND_STATICIP_RANGE_RESULTS+=($HOST)
    done
  done
  echo "${EXPAND_STATICIP_RANGE_RESULTS[@]}"
}

NODE_IP_LIST=$(expand_ip_range "$NODE_IP_RANGE" "$NUM_NODE_IP_RANGE")

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
  echo "$ACCEPTED_FINGERPRINTS"
}

NODE_CONFIG_LIST="\"${NODE_IP_LIST// /\",\"}\""
ACCEPTED_FINGERPRINTS=$(get_node_fingerprints "$NODE_IP_LIST")

# Create node provisioning document
sudo tee provision.json > /dev/null <<EOF
{
   "cassandra_config" : {
      "auto_bootstrap": false,
      "commitlog_sync_batch_window_in_ms": 2,
      "permissions_validity_in_ms" : 2000,
      "memtable_allocation_type" : "heap_buffers",
      "column_index_size_in_kb" : 64,
      "commitlog_sync_period_in_ms" : 10000,
      "native_transport_max_threads" : 128,
      "partitioner" : "org.apache.cassandra.dht.Murmur3Partitioner",
      "ssl_storage_port" : 7001,
      "authorizer" : "AllowAllAuthorizer",
      "tombstone_warn_threshold" : 1000,
      "commitlog_total_space_in_mb" : 8192,
      "dynamic_snitch_reset_interval_in_ms" : 600000,
      "tombstone_failure_threshold" : 100000,
      "cross_node_timeout" : false,
      "commit_failure_policy" : "stop",
      "counter_write_request_timeout_in_ms" : 5000,
      "endpoint_snitch" : "com.datastax.bdp.snitch.DseSimpleSnitch",
      "request_scheduler" : "org.apache.cassandra.scheduler.NoScheduler",
      "cas_contention_timeout_in_ms" : 1000,
      "memtable_heap_space_in_mb" : 2048,
      "concurrent_reads" : 32,
      "max_hint_window_in_ms" : 10800000,
      "start_native_transport" : true,
      "row_cache_save_period" : 0,
      "auto_snapshot" : true,
      "counter_cache_save_period" : 7200,
      "read_request_timeout_in_ms" : 5000,
      "saved_caches_directory" : "/var/lib/cassandra/saved_caches",
      "trickle_fsync_interval_in_kb" : 10240,
      "data_file_directories" : [
         "/var/lib/cassandra/data"
      ],
      "rpc_port" : 9160,
      "native_transport_port" : 9042,
      "start_rpc" : true,
      "incremental_backups" : false,
      "dynamic_snitch_update_interval_in_ms" : 100,
      "concurrent_counter_writes" : 32,
      "internode_authenticator" : "org.apache.cassandra.auth.AllowAllInternodeAuthenticator",
      "index_summary_resize_interval_in_minutes" : 60,
      "row_cache_size_in_mb" : 0,
      "sstable_preemptive_open_interval_in_mb" : 50,
      "compaction_throughput_mb_per_sec" : 16,
      "request_timeout_in_ms" : 10000,
      "internode_compression" : "dc",
      "batchlog_replay_throttle_in_kb" : 1024,
      "disk_failure_policy" : "stop",
      "rpc_server_type" : "sync",
      "authenticator" : "AllowAllAuthenticator",
      "key_cache_save_period" : 14400,
      "dynamic_snitch_badness_threshold" : 0.1,
      "trickle_fsync" : false,
      "commitlog_sync" : "periodic",
      "concurrent_writes" : 32,
      "stream_throughput_outbound_megabits_per_sec" : 200,
      "max_hints_delivery_threads" : 2,
      "hinted_handoff_enabled" : "true",
      "memory_allocator" : "NativeAllocator",
      "rpc_keepalive" : true,
      "truncate_request_timeout_in_ms" : 60000,
      "client_encryption_options" : {
         "keystore" : "resources/dse/conf/.keystore",
         "protocol" : "TLS",
         "algorithm" : "SunX509",
         "keystore_password" : "cassandra",
         "store_type" : "JKS",
         "truststore" : "resources/dse/conf/.truststore",
         "truststore_password" : "cassandra",
         "enabled" : false,
         "require_client_auth" : false,
         "cipher_suites" : [
            "TLS_RSA_WITH_AES_128_CBC_SHA",
            "TLS_RSA_WITH_AES_256_CBC_SHA",
            "TLS_DHE_RSA_WITH_AES_128_CBC_SHA",
            "TLS_DHE_RSA_WITH_AES_256_CBC_SHA",
            "TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA",
            "TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA"
         ]
      },
      "hinted_handoff_throttle_in_kb" : 1024,
      "storage_port" : 7000,
      "commitlog_segment_size_in_mb" : 32,
      "native_transport_max_frame_size_in_mb" : 256,
      "commitlog_directory" : "/var/lib/cassandra/commitlog",
      "batch_size_warn_threshold_in_kb" : 64,
      "inter_dc_tcp_nodelay" : false,
      "snapshot_before_compaction" : false,
      "thrift_framed_transport_size_in_mb" : 15,
      "write_request_timeout_in_ms" : 2000,
      "range_request_timeout_in_ms" : 10000,
      "memtable_offheap_space_in_mb" : 2048,
      "cluster_name" : "test01",
      "server_encryption_options" : {
         "keystore_password" : "cassandra",
         "algorithm" : "SunX509",
         "internode_encryption" : "none",
         "protocol" : "TLS",
         "keystore" : "conf/.keystore",
         "truststore" : "conf/.truststore",
         "store_type" : "JKS",
         "truststore_password" : "cassandra",
         "cipher_suites" : [
            "TLS_RSA_WITH_AES_128_CBC_SHA",
            "TLS_RSA_WITH_AES_256_CBC_SHA",
            "TLS_DHE_RSA_WITH_AES_128_CBC_SHA",
            "TLS_DHE_RSA_WITH_AES_256_CBC_SHA",
            "TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA",
            "TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA"
         ],
         "require_client_auth" : false
      }
   },
   "is_retry" : false,
   "install_params" : {
      "package" : "dse",
      "private_key" : "",
      "password" : "${ADMIN_PASSWORD}",
      "username" : "${ADMIN_USERNAME}",
      "version" : "${DSE_VERSION}",
      "repo-password" : "${DATASTAX_PASSWORD}",
      "repo-user" : "${DATASTAX_USERNAME}"
   },
   "local_datacenters" : [
      {
         "location" : "",
         "node_information" : [
            {
               "public_ip" : "10.0.100.100",
               "private_ip" : "10.0.100.100",
               "node_type" : "cassandra"
            },
            {
               "node_type" : "cassandra",
               "private_ip" : "10.0.100.101",
               "public_ip" : "10.0.100.101"
            }
         ],
         "dc" : ""
      }
   ]
}
EOF

# Write this somewhere we can look at it later for debugging
cat provision.json > /var/log/azure/provision.json

# Give OpsCenter a bit to come up and then provision a new cluster
sleep 200

# Login and get session token
AUTH_SESSION=$(curl -k -X POST -d '{"username":"admin","password":"admin"}' 'https://127.0.0.1:8443/login' | sed -e 's/^.*"sessionid"[ ]*:[ ]*"//' -e 's/".*//')

# Provision a new cluster with the nodes passed
curl -k -H "opscenter-session: $AUTH_SESSION" -H "Accept: application/json" -X POST https://127.0.0.1:8443/provision -d @provision.json

#Update the admin password with the one passed as parameter
curl -k -H "opscenter-session: $AUTH_SESSION" -H "Accept: application/json" -d "{\"password\": \"$ADMIN_PASSWORD\", \"role\": \"admin\" }" -X PUT https://127.0.0.1:8443/users/admin

