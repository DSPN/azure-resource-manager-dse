#/bin/sh

RESOURCE_GROUP=$1
azure group create $RESOURCE_GROUP "East Asia"

# This writes output to generatedTemplate.json using clusterParameters.json as input
python main.py

azure group deployment create -f ./generatedTemplate.json $RESOURCE_GROUP dse

