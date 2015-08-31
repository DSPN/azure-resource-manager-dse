#!/bin/sh

RG1="bengroup3"
RG2="bengroup5"

#azure group create $1 "East Asia"
#azure group create $2 "West US"

#azure group deployment create -f ../../../simple/mainTemplate.json -e ../../../simple/mainTemplateParameters.json $RG1 t0 &
#azure group deployment create -f ../../simpleAlternateSubnet/mainTemplate.json -e ../../simpleAlternateSubnet/mainTemplateParameters.json $RG2 t0 &

#azure group deployment create -f ./gateway1.json -e ./gateway1parameters.json $RG1 t0 &
azure group deployment create -f ./gateway2.json -e ./gateway2parameters.json $RG2 t0 &

# note you will have to modify the parameters file as the gateway names are hard coded in it.
#azure group deployment create -f ./connect.json -e ./connectParameters.json $RG1 t0 
