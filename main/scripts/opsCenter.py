import json
import os
import sys
import base64


def run():
    if len(sys.argv) != 2:
        print("I need an argument.")
        exit(1)

    clusterParameters = json.loads(base64.b64decode(sys.argv[1]))
    regions = clusterParameters['regions']
    nodesPerRegion = clusterParameters['nodesPerRegion']
    username = clusterParameters['username']
    password = clusterParameters['password']

    document = generateDocument(username, password, regions, nodesPerRegion)

    with open('provision.json', 'w') as outputFile:
        json.dump(document, outputFile, sort_keys=True, indent=4, ensure_ascii=False)


def getNodeInformation(datacenterIndex, numberOfNodes):
    nodeInformation = []

    for nodeIndex in range(0, numberOfNodes):
        nodeIP = '10.' + str(datacenterIndex) + '.1.' + str(nodeIndex + 5)
        document = {
            "public_ip": nodeIP,
            "private_ip": nodeIP,
            "node_type": "cassandra",
            "rack": "rack1"
        }
        nodeInformation.append(document)
    return nodeInformation


def getLocalDataCenters(regions, nodesPerRegion):
    localDataCenters = []
    for region in regions:
        datacenterIndex = regions.index(region) + 1
        localDataCenter = {
            "location": region,
            "node_information": getNodeInformation(datacenterIndex, nodesPerRegion),
            "dc": region.replace(" ", "_").lower()
        }
        localDataCenters.append(localDataCenter)
    return localDataCenters


def getFingerprint(ip):
    os.system('ssh-keyscan -p 22 -t rsa ' + ip + ' > /tmp/tmpsshkeyhost.pub')
    os.system('ssh-keygen -lf /tmp/tmpsshkeyhost.pub > /tmp/tmpgenkey')

    with open("/tmp/tmpgenkey", "r") as inputFile:
        data = inputFile.read()
    array = data.split()
    fingerprint = array[0] + ' ' + array[1] + ' ' + array[3]
    return fingerprint


def getAcceptedFingerprints(regions, nodesPerRegion):
    acceptedFingerprints = {}
    for region in regions:
        datacenterIndex = regions.index(region) + 1
        for nodeIndex in range(0, nodesPerRegion):
            nodeIP = '10.' + str(datacenterIndex) + '.1.' + str(nodeIndex + 5)
            acceptedFingerprints[nodeIP] = getFingerprint(nodeIP)

    return acceptedFingerprints


def generateDocument(username, password, regions, nodesPerRegion):
    localDataCenters = getLocalDataCenters(regions, nodesPerRegion)
    acceptedFingerprints = getAcceptedFingerprints(regions, nodesPerRegion)

    return {
        "cassandra_config": {
            "phi_convict_threshold": 12,
            "num_tokens": 64,
            "auto_bootstrap": False,
            "permissions_validity_in_ms": 2000,
            "memtable_allocation_type": "heap_buffers",
            "column_index_size_in_kb": 64,
            "commitlog_sync_period_in_ms": 10000,
            "native_transport_max_threads": 128,
            "partitioner": "org.apache.cassandra.dht.Murmur3Partitioner",
            "ssl_storage_port": 7001,
            "authorizer": "AllowAllAuthorizer",
            "tombstone_warn_threshold": 1000,
            "commitlog_total_space_in_mb": 8192,
            "dynamic_snitch_reset_interval_in_ms": 600000,
            "tombstone_failure_threshold": 100000,
            "cross_node_timeout": False,
            "commit_failure_policy": "stop",
            "counter_write_request_timeout_in_ms": 5000,
            "endpoint_snitch": "org.apache.cassandra.locator.GossipingPropertyFileSnitch",
            "request_scheduler": "org.apache.cassandra.scheduler.NoScheduler",
            "cas_contention_timeout_in_ms": 1000,
            "memtable_heap_space_in_mb": 2048,
            "concurrent_reads": 32,
            "max_hint_window_in_ms": 10800000,
            "start_native_transport": True,
            "row_cache_save_period": 0,
            "auto_snapshot": True,
            "counter_cache_save_period": 7200,
            "read_request_timeout_in_ms": 5000,
            "saved_caches_directory": "/mnt/saved_caches",
            "trickle_fsync_interval_in_kb": 10240,
            "data_file_directories": [
                "/mnt/data"
            ],
            "rpc_port": 9160,
            "native_transport_port": 9042,
            "start_rpc": True,
            "incremental_backups": False,
            "dynamic_snitch_update_interval_in_ms": 100,
            "concurrent_counter_writes": 32,
            "internode_authenticator": "org.apache.cassandra.auth.AllowAllInternodeAuthenticator",
            "index_summary_resize_interval_in_minutes": 60,
            "row_cache_size_in_mb": 0,
            "sstable_preemptive_open_interval_in_mb": 50,
            "compaction_throughput_mb_per_sec": 16,
            "request_timeout_in_ms": 10000,
            "internode_compression": "dc",
            "batchlog_replay_throttle_in_kb": 1024,
            "disk_failure_policy": "stop",
            "rpc_server_type": "sync",
            "authenticator": "AllowAllAuthenticator",
            "key_cache_save_period": 14400,
            "dynamic_snitch_badness_threshold": 0.1,
            "trickle_fsync": False,
            "commitlog_sync": "periodic",
            "concurrent_writes": 32,
            "stream_throughput_outbound_megabits_per_sec": 200,
            "max_hints_delivery_threads": 2,
            "hinted_handoff_enabled": "true",
            "memory_allocator": "NativeAllocator",
            "rpc_keepalive": True,
            "truncate_request_timeout_in_ms": 60000,
            "client_encryption_options": {
                "keystore": "resources/dse/conf/.keystore",
                "protocol": "TLS",
                "algorithm": "SunX509",
                "keystore_password": "cassandra",
                "store_type": "JKS",
                "truststore": "resources/dse/conf/.truststore",
                "truststore_password": "cassandra",
                "enabled": False,
                "require_client_auth": False,
                "cipher_suites": [
                    "TLS_RSA_WITH_AES_128_CBC_SHA",
                    "TLS_RSA_WITH_AES_256_CBC_SHA",
                    "TLS_DHE_RSA_WITH_AES_128_CBC_SHA",
                    "TLS_DHE_RSA_WITH_AES_256_CBC_SHA",
                    "TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA",
                    "TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA"
                ]
            },
            "hinted_handoff_throttle_in_kb": 1024,
            "storage_port": 7000,
            "commitlog_segment_size_in_mb": 32,
            "native_transport_max_frame_size_in_mb": 256,
            "commitlog_directory": "/mnt/commitlog",
            "batch_size_warn_threshold_in_kb": 64,
            "inter_dc_tcp_nodelay": False,
            "snapshot_before_compaction": False,
            "thrift_framed_transport_size_in_mb": 15,
            "write_request_timeout_in_ms": 2000,
            "range_request_timeout_in_ms": 10000,
            "memtable_offheap_space_in_mb": 2048,
            "cluster_name": "Test Cluster",
            "server_encryption_options": {
                "keystore_password": "cassandra",
                "algorithm": "SunX509",
                "internode_encryption": "none",
                "protocol": "TLS",
                "keystore": "conf/.keystore",
                "truststore": "conf/.truststore",
                "store_type": "JKS",
                "truststore_password": "cassandra",
                "cipher_suites": [
                    "TLS_RSA_WITH_AES_128_CBC_SHA",
                    "TLS_RSA_WITH_AES_256_CBC_SHA",
                    "TLS_DHE_RSA_WITH_AES_128_CBC_SHA",
                    "TLS_DHE_RSA_WITH_AES_256_CBC_SHA",
                    "TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA",
                    "TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA"
                ],
                "require_client_auth": False
            }
        },
        "is_retry": False,
        "install_params": {
            "package": "dse",
            "private_key": "",
            "password": password,
            "username": username,
            "version": "4.8.0",
            "repo-password": "3A7vadPHbNT",
            "repo-user": "datastax%40microsoft.com"
        },
        "local_datacenters": localDataCenters,
        "accepted_fingerprints": acceptedFingerprints
    }


run()
