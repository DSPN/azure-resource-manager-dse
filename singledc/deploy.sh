#!/bin/bash

resource_group='dse'
location='eastus'
usage="---------------------------------------------------
Usage:
deploy.sh [-h] [-g resource-group] [-l location]

Options:

 -h                 : display this message and exit
 -g resource-group  : name of resource group to create, default 'dse'
 -l location        : location for resource group, default 'eastus'

---------------------------------------------------"


while getopts 'hg:l:' opt; do
  case $opt in
    h) echo -e "$usage"
       exit 1
    ;;
    g) resource_group="$OPTARG"
    ;;
    l) location="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
        exit 1
    ;;
  esac
done


if [ -z "$(which az)" ]; then
    echo "CLI v2 'az' command not found. Please install: https://docs.microsoft.com/en-us/cli/azure/install-az-cli2"
    exit 1
fi

echo "CLI v2 'az' command found"
echo "Using values: resource_group=$resource_group location=$location"

eco "WARNING: baseUrl hardcoded to rr branch"

az group create --name $resource_group --location $location
az group deployment create \
 --resource-group $resource_group \
 --template-file mainTemplate.json \
 --parameters @mainTemplateParameters.json \
 --verbose
