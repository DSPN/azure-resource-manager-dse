#!/bin/bash

echo $(basename "$0") "$@"
data_center_name=$1
seed_node_public_ip=$2
opscenter_public_ip=$3
node_public_ip=$4
node_private_ip=$5

cloud_type=azure # azure or aws
default_seed_node_public_ip=104.40.22.205
default_opscenter_public_ip=40.112.212.167

#Make sure file systems were built
data_file_directories="/mnt/cassandra/data"
commitlog_directory="/mnt/cassandra/commitlog"
saved_caches_directory="/mnt/cassandra/saved_caches"

if [ -n $data_center_name ]; then		data_center_name=`printf '%s' 'data_center_name: ' >&2; read val; echo $val;`; fi
if [ -n $seed_node_public_ip ]; then		seed_node_public_ip=$default_seed_node_public_ip; fi
if [ -n $opscenter_public_ip ]; then 		opscenter_public_ip=$default_opscenter_public_ip; fi
if [ -n $node_public_ip ]; then 		node_public_ip=`curl --max-time 50000 --retry 12 --retry-delay 50000 -s 'http://checkip.dyndns.org' | sed 's/.*Current IP Address: \([0-9\.]*\).*/\1/g'`; fi
if [ -n $node_private_ip ]; then		node_private_ip=`echo $(hostname -I)`; fi

echo ''
echo data_center_name \'$data_center_name\'
echo seed_node_public_ip \'$seed_node_public_ip\'
echo opscenter_public_ip \'$opscenter_public_ip\'
echo node_public_ip \'$node_public_ip\'
echo node_private_ip \'$node_private_ip\'

#
# Determine Rack
#
if [ $cloud_type == "azure" ]; then
	# Determine Fault Domain used to create the Rack name to create rackdc.properties
	# to allow cassandra to place each of 3 replicas on separate fault domains
	fault_domain=$(curl --max-time 50000 --retry 12 --retry-delay 50000 http://169.254.169.254/metadata/v1/InstanceInfo -s -S | sed -e 's/.*"FD":"\([^"]*\)".*/\1/')
	if [ ! "$fault_domain" ]; then
		echo Unable to retrieve Instance Fault Domain from instance metadata server 1>&2
		exit 99
	fi
	echo Fault Domain: "$fault_domain"
	rack="FD$fault_domain"
fi
if [ $cloud_type == "aws" ]; then
	availability_zone=$( curl --max-time 50000 --retry 12 --retry-delay 50000 http://169.254.169.254/latest/meta-data/placement/availability-zone -s -S )
	if [ ! "$availability_zone" ]; then
		echo Unable to retrieve Instance Availability Zone from instance metadata server 1>&2
		exit 99
	fi
	echo Availability Zone: "$availability_zone"
	rack=$(echo $availability_zone | sed -e 's/-/_/g')
fi
echo rack: $rack
echo ""

set -x

#--- download and Install Java ---#
echo | add-apt-repository ppa:webupd8team/java
apt-get -y  update
apt-get -y  install oracle-java8-installer
apt-get -y  install oracle-java8-set-default
java -version
echo | update-alternatives --force --config java
java -version

#--- Install Utilities ---#
apt-get -y install apt-show-versions
apt-get -y install mlocate
apt-get -y install vim-enhanced
apt-get -y install tree
apt-get -y install telnet

#---download and Install dse
echo Installing DSE
echo "deb https://datastax%40microsoft.com:3A7vadPHbNT@debian.datastax.com/enterprise stable main" | sudo tee -a /etc/apt/sources.list.d/datastax.sources.list
curl -L https://debian.datastax.com/debian/repo_key | sudo apt-key add -
apt-get -y update
apt-get -y install dse-full

set +x

#
# Preconfigure and tune Cassandra and DataStax Agent
#
cassandra_conf_dir=/etc/dse/cassandra
agent_conf_dir=/var/lib/datastax-agent/conf
security_dir=/etc/security
limitd_dir=/etc/security/limits.d

date=$(date +%F)
cassandraenv_backup="cassandra-env.sh.$date"
cassandrayaml_backup="cassandra.yaml.$date"
rackdc_properties_backup="cassandra-rackdc.properties.$date"
addressyaml_backup="address.yaml.$date"
limitsconf_backup="limits.conf.$date"
limitd_backup="cassandra.conf.$date"


#
# Create backup files if they don't exist
#
cd "$cassandra_conf_dir"

if [ ! -f "$cassandraenv_backup" ] ; then
	( set -x
		cp cassandra-env.sh "$cassandraenv_backup"
		chown cassandra:cassandra "$cassandraenv_backup"
	)
fi

if [ ! -f "$cassandrayaml_backup" ] ; then
	( set -x
		cp cassandra.yaml "$cassandrayaml_backup"
		chown cassandra:cassandra "$cassandrayaml_backup"
	)
fi

if [ ! -f "$rackdc_properties_backup" ] ; then
	( set -x
		cp cassandra-rackdc.properties "$rackdc_properties_backup"
		chown cassandra:cassandra "$rackdc_properties_backup"
	)
fi

cd "$agent_conf_dir"

if [ ! -f "$addressyaml_backup" ] ; then
	if [ ! -f address.yaml ] ; then
		( echo address.yaml empty; set -x ; touch address.yaml )
		(set -x; chown cassandra:cassandra address.yaml)
	fi
	( set -x
		cp address.yaml "$addressyaml_backup"
		chown cassandra:cassandra "$addressyaml_backup"
	)
fi

cd "$security_dir"

if [ ! -f "$limitsconf_backup" ] ; then
	( set -x
		cp limits.conf "$limitsconf_backup"
		chown cassandra:cassandra "$limitsconf_backup"
	)
fi

cd "$cassandra_conf_dir"
#
# Generate cassandra-env.sh.new
#
MAX_HEAP_SIZE="14G"
HEAP_NEWSIZE="3G"

# Change values and uncomment if needed
cat cassandra-env.sh \
| sed -e "s:^[#]*\(MAX_HEAP_SIZE\=\).*:MAX_HEAP_SIZE\=\"$MAX_HEAP_SIZE\":" \
| sed -e "s:^[#]*\(HEAP_NEWSIZE\=\).*:HEAP_NEWSIZE\=\"$HEAP_NEWSIZE\":" \
> cassandra-env.sh.new
(set -x; chown cassandra:cassandra cassandra-env.sh.new)
(set -x; diff cassandra-env.sh cassandra-env.sh.new)
(set -x; mv -f cassandra-env.sh.new cassandra-env.sh)


set -x
#
# Generate cassandra.yaml
#
cluster_name='Cluster'
seeds="$seed_node_public_ip"
listen_address=$node_private_ip
broadcast_address=$node_public_ip
rpc_address=$node_private_ip
broadcast_rpc_address=$node_public_ip
endpoint_snitch="GossipingPropertyFileSnitch"
num_tokens=64

concurrent_reads=64
concurrent_writes=64
memtable_flush_writers=3
concurrent_compactors=2
compaction_throughput_mb_per_sec=0
commitlog_segment_size_in_mb=64
compaction_throughput_mb_per_sec=100
phi_convict_threshold=12
inter_dc_stream_throughput_outbound_megabits_per_sec=100
write_request_timeout_in_ms=3000

# TODO: Change the "-" substitutions to a  multi-line sed pattern substitution.
cat cassandra.yaml \
| sed -e "s:.*\(cluster_name\:\).*:cluster_name\: \'$cluster_name\':" \
| sed -e "s:\(.*- *seeds\:\).*:\1 \"$seeds\":" \
| sed -e "s:[# ]*\(listen_address\:\).*:listen_address\: $listen_address:" \
| sed -e "s:[# ]*\(broadcast_address\:\).*:broadcast_address\: $broadcast_address:" \
| sed -e "s:[# ]*\(rpc_address\:\).*:rpc_address\: $rpc_address:" \
| sed -e "s:[# ]*\(broadcast_rpc_address\:\).*:broadcast_rpc_address\: $broadcast_rpc_address:" \
| sed -e "s:.*\(endpoint_snitch\:\).*:endpoint_snitch\: $endpoint_snitch:" \
| sed -e "s:.*\(num_tokens\:\).*:\1 $num_tokens:" \
| sed -e "s:\(.*- \)/var/lib/cassandra/data.*:\1$data_file_directories:" \
| sed -e "s:.*\(commitlog_directory\:\).*:commitlog_directory\: $commitlog_directory:" \
| sed -e "s:.*\(saved_caches_directory\:\).*:saved_caches_directory\: $saved_caches_directory:" \
| sed -e "s:.*\(concurrent_reads\:\).*:concurrent_reads\: $concurrent_reads:" \
| sed -e "s:.*\(concurrent_writes\:\).*:concurrent_writes\: $concurrent_writes:" \
| sed -e "s:.*\(memtable_flush_writers\:\).*:memtable_flush_writers\: $memtable_flush_writers:" \
| sed -e "s:.*\(concurrent_compactors\:\).*:concurrent_compactors\: $concurrent_compactors:" \
| sed -e "s:.*\(compaction_throughput_mb_per_sec\:\).*:compaction_throughput_mb_per_sec\: $compaction_throughput_mb_per_sec:" \
| sed -e "s:.*\(phi_convict_threshold\:\).*:phi_convict_threshold\: $phi_convict_threshold:" \
| sed -e "s:.*\(inter_dc_stream_throughput_outbound_megabits_per_sec\:\).*:inter_dc_stream_throughput_outbound_megabits_per_sec\: $inter_dc_stream_throughput_outbound_megabits_per_sec:" \
| sed -e "s:.*\(write_request_timeout_in_ms\:\).*:write_request_timeout_in_ms\: $write_request_timeout_in_ms:" \
> cassandra.yaml.new
(set -x; chown cassandra:cassandra cassandra.yaml.new)
(set -x; diff cassandra.yaml cassandra.yaml.new)
(set -x; mv -f cassandra.yaml.new cassandra.yaml )

#
# generate cassandra-rackdc.properties.new
#
dc=$data_center_name
rack=$rack
cat cassandra-rackdc.properties \
| sed -e "s:^\(dc\=\).*:dc\=$dc:" \
| sed -e "s:^\(rack\=\).*:rack\=$rack:" \
> cassandra-rackdc.properties.new
(set -x; chown cassandra:cassandra cassandra-rackdc.properties.new)
(set -x; diff cassandra-rackdc.properties cassandra-rackdc.properties.new)
(set -x; mv -f cassandra-rackdc.properties.new cassandra-rackdc.properties )
#
# generate address.yaml.new
#
cd "$agent_conf_dir"
stomp_interface=$opscenter_public_ip
local_interface=$node_private_ip
agent_rpc_broadcast_address=$node_public_ip
agent_rpc_interface=$node_private_ip
use_ssl=0
thrift_max_conns=10
async_pool_size=10
async_queue_size=800000
max_reconnect_time=60000
cat address.yaml \
| sed -e "s:.*\(stomp_interface\:\).*:stomp_interface\: $stomp_interface:" \
| sed -e "s:.*\(local_interface\:\).*:hosts\: \[\"$local_interface\"\]:" \
| sed -e "s:.*\(hosts\:\).*:hosts\: \[\"$local_interface\"\]:" \
| sed -e "s:.*\(use_ssl\:\).*:use_ssl\: $use_ssl:" \
| sed -e "s:.*\(thrift_max_conns\:\).*:thrift_max_conns\: $thrift_max_conns:" \
| sed -e "s:.*\(async_pool_size\:\).*:async_pool_size\: $async_pool_size:" \
| sed -e "s:.*\(max_reconnect_time\:\).*:max_reconnect_time\: $max_reconnect_time:" \
> address.yaml.new
if [ "x$(grep stomp_interface address.yaml)" == x ]; then echo "stomp_interface: $stomp_interface" >> address.yaml.new; fi
if [ "x$(grep hosts address.yaml)" == x ]; then echo "hosts: [\"$local_interface\"]" >> address.yaml.new; fi
if [ "x$(grep use_ssl address.yaml)" == x ]; then echo "use_ssl: $use_ssl" >> address.yaml.new; fi
if [ "x$(grep thrift_max_conns address.yaml)" == x ]; then echo "thrift_max_conns: $thrift_max_conns" >> address.yaml.new; fi
if [ "x$(grep async_pool_size address.yaml)" == x ]; then echo "async_pool_size: $async_pool_size" >> address.yaml.new; fi
if [ "x$(grep async_queue_size address.yaml)" == x ]; then echo "async_queue_size: $async_queue_size" >> address.yaml.new; fi
if [ "x$(grep max_reconnect_time address.yaml)" == x ]; then echo "max_reconnect_time: $max_reconnect_time" >> address.yaml.new; fi
(set -x; chown cassandra:cassandra address.yaml.new)
(set -x; diff address.yaml address.yaml.new)
(set -x; mv -f address.yaml.new address.yaml)

#
# configure limits
#
cd "$security_dir"
cat limits.conf \
| grep -v 'root.*memlock.*' \
| grep -v 'root.*nofile.*' \
| grep -v 'root.*nproc.*' \
| grep -v 'root.*as.*' \
| grep -v 'cassandra.*memlock.*' \
| grep -v 'cassandra.*nofile.*' \
| grep -v 'cassandra.*nproc.*' \
| grep -v 'cassandra.*as.*' \
> limits.conf.new
cat <</EOF >> limits.conf.new
root             -      memlock          unlimited
root             -      nofile           100000
root             -      nproc            32768
root             -      as               unlimited

cassandra        -      memlock          unlimited
cassandra        -      nofile           100000
cassandra        -      nproc            32768
cassandra        -      as               unlimited
/EOF
(set -x; chown cassandra:cassandra limits.conf.new)
(set -x; diff limits.conf limits.conf.new)
(set -x; mv -f limits.conf.new limits.conf)

mkdir $HOME/.cassandra
set -x; chown cassandra:cassandra $HOME/.cassandra
chmod 777 $HOME/.cassandra
cat <</EOF >$HOME/.cassandra/cqlshrc
[connection]
client_timeout = 600
hostname = $node_private_ip
port = 9042
/EOF
(set -x; chown cassandra:cassandra $HOME/.cassandra/cqlshrc)
(set -x; chmod 755 $HOME/.cassandra/cqlshrc)