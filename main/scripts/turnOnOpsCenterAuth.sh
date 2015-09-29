#!/bin/bash

# Enable authentication in /etc/opscenter/opscenterd.conf
sed -i '/^\[authentication\]$/,/^\[/ s/^enabled = False/enabled = True/' /etc/opscenter/opscenterd.conf

# Enable SSL - uncomment webserver SSL settings and leave them set to the default
sed -i '/^\[webserver\]$/,/^\[/ s/^#ssl_keyfile/ssl_keyfile/' /etc/opscenter/opscenterd.conf
sed -i '/^\[webserver\]$/,/^\[/ s/^#ssl_certfile/ssl_certfile/' /etc/opscenter/opscenterd.conf
sed -i '/^\[webserver\]$/,/^\[/ s/^#ssl_port/ssl_port/' /etc/opscenter/opscenterd.conf

echo "Restarting OpsCenter"
sudo service opscenterd restart

