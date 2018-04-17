#!/bin/bash

usage="
---------------------------------------------------
Usage:
deploy.sh [-h] -g resource-group -n num

Options:

 -h                 : display this message and exit
 -g resource-group  : PREFIX for name of resource group to DELETE
                      Resource groups assumed to be named prefix1 ... prefixN
 -n num             : number of deployments

---------------------------------------------------"


while getopts 'hg:n:' opt; do
  case $opt in
    h) echo -e "$usage"
       exit 1
    ;;
    g) resource_group="$OPTARG"
    ;;
    n) num="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
        exit 1
    ;;
  esac
done

if [ -z ${resource_group+x} ]; then
  echo "Required arg -g not passed. Run 'teardown.sh -h' for help."
  exit 1
fi

if [ -z ${num+x} ]; then
  echo "Required arg -n not passed. Run 'teardown.sh -h' for help."
  exit 1
fi


echo -e "\n\nWARNING: this will delete without prompting the following resource groups:"
for i in `seq 1 $num`;
do
  name="$resource_group$i"
  echo "$name"
done
echo -e "\n"

while true; do
    read -p "Are you sure? " yn
    case $yn in
        [Yy]* ) echo "Deleting resource groups..."; break;;
        [Nn]* ) echo "Exiting..."; exit;;
        * ) echo "Please answer [yY] or [nN].";;
    esac
done

for i in `seq 1 $num`;
do
  name="$resource_group$i"
  echo "Deleting: $name"
  az group delete -g $name --yes --no-wait
done
