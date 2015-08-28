#!/bin/sh

RESOURCE_GROUP=$1
azure group create $RESOURCE_GROUP "East Asia"
azure group deployment create -f ./mainTemplate.json $RESOURCE_GROUP t0

