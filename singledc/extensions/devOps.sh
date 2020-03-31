#!/bin/bash
set -e

subnetcider=$1
nodecount=$2
vmsize=$3
dc=$4
diskSize=$5
cluster_name=$6
deploy_opsc=$7
nic_offset=$8

# replace -
cluster_name=`sed 's/-/_/g' <<<"$cluster_name"`
echo "Input to devOpsc is:"
echo subnetcider $subnetcider
echo nodecount $nodecount
echo cluster_name $cluster_name
echo dc $dc
echo deploy_opsc $deploy_opsc
echo nic_offset $nic_offset
#
alias python=python3
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
cp /var/lib/waagent/custom-script/download/0/*.sh .
cp /var/lib/waagent/custom-script/download/0/hosts .
cp /var/lib/waagent/custom-script/download/0/*.cfg .
cp /var/lib/waagent/custom-script/download/0/*.yml .
cp /var/lib/waagent/custom-script/download/0/devops* .

# ansible setup
if [ -d "/etc/ansible" ]
then
  echo "/etc/ansible exists"
else
   mkdir /etc/ansible
fi
cp ansible.cfg /etc/ansible
cp hosts /etc/ansible
#
CIDR=`echo $subnetcider | awk -F. '{print $1"."$2"."$3"."}'`
#
truncate -s 0 /etc/ansible/hosts
#OPSC
echo -e [OPSC] >> /etc/ansible/hosts
echo -e "${CIDR}4" >> /etc/ansible/hosts
# SEED
SEEDSTART=$((5 + $nic_offset ))
echo -e [SEED] >> /etc/ansible/hosts
echo -e "${CIDR}${SEEDSTART}" >> /etc/ansible/hosts
# NODES
echo -e [DSE] >> /etc/ansible/hosts
START=$((1 + $nic_offset ))
END=$(( $nodecount + $nic_offset ))
IPSTART=$((6 + $nic_offset ))
echo START $START
echo END $END
echo IPSTART $IPSTART
while [ $END -gt $START ]; do
echo -e $CIDR$IPSTART
echo -e $CIDR$IPSTART >> /etc/ansible/hosts
let END=END-1
let IPSTART=IPSTART+1
done
seed1="${CIDR}5"
seeds="${CIDR}5,${CIDR}6"
opscip="${CIDR}4"

# ssh keys
cp /home/dse/dse-azure-install/devops /root/.ssh/id_rsa
cp /home/dse/dse-azure-install/devops.pub /root/.ssh/id_rsa.pub
cat < /home/dse/dse-azure-install/devops.pub >> /root/.ssh/authorized_keys


export ANSIBLE_HOST_KEY_CHECKING=False
# seed node
# check offset value before running although it is idempotent
/usr/bin/ansible-playbook -u root /home/dse/dse-azure-install/os-config.yml --extra-vars "host=SEED"
/usr/bin/ansible-playbook -u root /home/dse/dse-azure-install/ebs-init.yml --extra-vars "host=SEED"
/usr/bin/ansible-playbook -u root /home/dse/dse-azure-install/dse-directories.yml --extra-vars "host=SEED"
/usr/bin/ansible-playbook -u root /home/dse/dse-azure-install/dse-install.yml --extra-vars "host=SEED cluster_name=$cluster_name dc=$dc seeds=$seed1 opscip=$opscip"
# nodes
/usr/bin/ansible-playbook -u root /home/dse/dse-azure-install/os-config.yml -f 30 --extra-vars "host=DSE"
/usr/bin/ansible-playbook -u root /home/dse/dse-azure-install/ebs-init.yml -f 30 --extra-vars "host=DSE"
/usr/bin/ansible-playbook -u root /home/dse/dse-azure-install/dse-directories.yml -f 30 --extra-vars "host=DSE"
/usr/bin/ansible-playbook -u root /home/dse/dse-azure-install/dse-install.yml -f 30 --extra-vars "host=DSE cluster_name=$cluster_name dc=$dc seeds=$seeds opscip=$opscip"
# opsc
if [ "$deploy_opsc" == "true" ]; then
   /usr/bin/ansible-playbook -u root /home/dse/dse-azure-install/opscenter-install.yml --extra-vars "seeds=$seeds cluster_name=$cluster_name"
else
   echo "OPSC not being installed"
fi
# cleanup
/usr/bin/ansible-playbook -u root /home/dse/dse-azure-install/os-removekeys.yml --extra-vars "host=DSE" -vvv
/usr/bin/ansible-playbook -u root /home/dse/dse-azure-install/os-removekeys.yml --extra-vars "host=SEED" -vvv
rm -rf /home/dse/dse-azure-install
rm -f /home/dse/opscenter-6.7.7.tar.gz