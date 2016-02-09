#!/bin/bash

echo "Installing Java"
bash installJava.sh

echo "Modifying permissions"
chmod 777 /mnt

# This is a bit of a hack that should go away with OpsCenter 6.x provisioning
bash set_agent_rpc_broadcast_address.sh
