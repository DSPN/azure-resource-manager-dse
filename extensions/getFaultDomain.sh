#!/bin/bash

#
# Retrieve Fault Domain for an Azure virtual machine
# by Rich Rein 2016
#

# curl http://169.254.169.254/metadata/v1/InstanceInfo ; echo ''
# produces
# {"ID":"_dc1vm0","UD":"1","FD":"1"}

fault_domain=$(curl --max-time 50000 --retry 12 --retry-delay 50000 http://169.254.169.254/metadata/v1/InstanceInfo -s -S | sed -e 's/.*"FD":"\([^"]*\)".*/\1/')
if [ ! "$fault_domain" ]; then
	echo Unable to retrieve Instance Fault Domain from instance metadata server 1>&2
	exit 99
fi

echo "$fault_domain"
