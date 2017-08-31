#!/bin/bash

RESOURCE_GROUP=$1

# This uses clusterParameters.json as input and writes output to generatedTemplate.json
python main.py

if [ -z "$(which az)" ]
then
    echo "CLI v2 'az' command not found, falling back to v1 'azure'"
    azure group create $1 "eastus"
    azure group deployment create -f ./generatedTemplate.json $RESOURCE_GROUP dse

else
    echo "CLI v2 'az' command found"
    az group create --name $RESOURCE_GROUP --location "eastus"
    az group deployment create \
     --resource-group $RESOURCE_GROUP \
     --template-file generatedTemplate.json \
     --verbose
fi

