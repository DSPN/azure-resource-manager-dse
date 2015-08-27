#!/bin/sh

RESOURCE_GROUP=$1

azure group create $RESOURCE_GROUP "East Asia"

### This group will be created in East Asia
azure group deployment create -f ../../..simple/mainTemplate.json -e ../../..simple/mainTemplateParameters.json $RESOURCE_GROUP t0

### Going to hard code this to create in West US
azure group deployment create -f ../../simpleAlternateSubnet/mainTemplate.json -e ../../simpleAlternateSubnet/mainTemplateParameters.json $RESOURCE_GROUP t0

azure group deployment create -f ./connect.json -e ./connectParameters.json $RESOURCE_GROUP t0 &



