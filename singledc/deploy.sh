#!/bin/sh

RESOURCE_GROUP=$1

azure group create $1 "East Asia"
azure group deployment create -f mainTemplate.json -e mainTemplateParameters.json $RESOURCE_GROUP dse

