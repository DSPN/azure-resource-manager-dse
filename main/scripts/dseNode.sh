#!/bin/bash

bash installJava.sh

echo "Partitioning and formatting all attached data disks"
bash vm-disk-utils-0.1.sh

echo "Modifying permissions"
chmod 777 /mnt

