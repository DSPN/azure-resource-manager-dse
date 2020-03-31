#!/bin/bash
set -e


alias python=python3
#
# initial directories for ansible and shell
#
echo "DSE Deploy : create base dirs"
cd /home/dse
if [ -d "/home/dse/dse-azure-install" ]
then
  echo "dse-azure-install exists"
else
  mkdir dse-azure-install
fi
cd dse-azure-install
#
echo "DSE Deploy : copy ansible playbooks and shell to base dirs"
cp /var/lib/waagent/custom-script/download/0/*.pub .
cp /var/lib/waagent/custom-script/download/0/cassconf .
cp /var/lib/waagent/custom-script/download/0/*.service .
cp /var/lib/waagent/custom-script/download/0/start-cassandra .
cp /var/lib/waagent/custom-script/download/0/stop-cassandra .
#
cat < /home/dse/dse-azure-install/devops.pub >> /root/.ssh/authorized_keys
