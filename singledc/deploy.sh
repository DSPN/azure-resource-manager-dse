#!/bin/bash

resource_group='dse'
location='eastus'
usage="---------------------------------------------------
Usage:
deploy.sh [-h] [-g resource-group] [-l location] [-t]

Options:

 -h                 : display this message and exit
 -g resource-group  : name of resource group to create, default 'dse'
 -l location        : location for resource group, default 'eastus'
 -t                 : testing flag, sets baseUrl to dev branch

---------------------------------------------------"


while getopts 'hg:l:t' opt; do
  case $opt in
    h) echo -e "$usage"
       exit 1
    ;;
    g) resource_group="$OPTARG"
    ;;
    l) location="$OPTARG"
    ;;
    t) testing="true"
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

if [ -n "$testing" ]; then
    if [ -x "$(git branch --list | grep '*' | grep 'dev')" ]; then echo "Not on dev branch, exiting."; exit 1; fi
    echo "Testing... setting baseUrl to dev branch..."
    az group create --name $resource_group --location $location
    az group deployment create \
     --resource-group $resource_group \
     --template-file mainTemplate.json \
     --parameters @mainTemplateParameters.json \
     --parameters '{"baseUrl": {"value": "https://raw.githubusercontent.com/DSPN/azure-resource-manager-dse/dev"}}' \
     --verbose
else
    az group create --name $resource_group --location $location
    az group deployment create \
     --resource-group $resource_group \
     --template-file mainTemplate.json \
     --parameters @mainTemplateParameters.json \
     --verbose
fi
