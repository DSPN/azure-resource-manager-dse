#!/usr/bin/env bash

# Azure public IPs have some odd keepalive behavior.
# A good summary is available here: https://docs.mongodb.org/ecosystem/platforms/windows-azure/

echo "Going to set the TCP keepalive for now."
sysctl -w net.ipv4.tcp_keepalive_time=120

echo "Going to set the TCP keepalive permanently across reboots."
echo "net.ipv4.tcp_keepalive_time = 120" >> /etc/sysctl.conf
echo "" >> /etc/sysctl.conf
