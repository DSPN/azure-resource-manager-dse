#!/bin/sh

RG1=$1
RG2=$2

#azure group create $1 "East Asia"
#azure group create $2 "West US"

#azure group deployment create -f ../simple/mainTemplate.json -e ../simple/mainTemplateParameters.json $RG1 t0 &
#azure group deployment create -f ./simpleAlternateSubnet/mainTemplate.json -e ./simpleAlternateSubnet/mainTemplateParameters.json $RG2 t0 &

azure group deployment create -f ./connectVnet/acrossResourceGroups/vnet1.json -e ./connectVnet/acrossResourceGroups/vnet1parameters.json t0 &
#azure group deployment create -f ./connectVnet/acrossResourceGroups/vnet2.json -e ./connectVnet/acrossResourceGroups/vnet2parameters.json t0 &

