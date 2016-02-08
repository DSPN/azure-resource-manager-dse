#!/usr/bin/env bash

# By default OpsCenter will use the private IP for the stomp interface.
# The agents on nodes won't be able to connect to that.

PUBLICIP=`curl --max-time 50000 --retry 12 --retry-delay 50000 -s 'http://checkip.dyndns.org' | sed 's/.*Current IP Address: \([0-9\.]*\).*/\1/g'`
echo 'My public IP address is '$PUBLICIP

echo "Making changes to the OpsCenter config based on my public IP."
echo '[agents]' >> /etc/opscenter/opscenterd.conf
echo 'reported_interface='$PUBLICIP >> /etc/opscenter/opscenterd.conf
