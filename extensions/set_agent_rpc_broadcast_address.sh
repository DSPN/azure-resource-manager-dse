#!/usr/bin/env bash

PUBLICIP=`curl --max-time 50000 --retry 12 --retry-delay 50000 -s 'http://checkip.dyndns.org' | sed 's/.*Current IP Address: \([0-9\.]*\).*/\1/g'`
echo 'My public IP address is '$PUBLICIP

echo "We need to tell the datastax-agent to bind to its publicip."
mkdir /var/lib/datastax-agent
mkdir /var/lib/datastax-agent/conf
echo 'agent_rpc_broadcast_address: '$PUBLICIP >> /var/lib/datastax-agent/conf/address.yaml
