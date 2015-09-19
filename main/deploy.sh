#/bin/sh

RESOURCE_GROUP=$1
azure group create $RESOURCE_GROUP "East Asia"

# This writes our generated template to template.json
python buildTemplate.py input.json

#azure group deployment create -f ./template.json $RESOURCE_GROUP dse






#########
### old
#########

#azure group deployment create -f ./vnet.json -p "{\"region\": {\"value\": \"East Asia\"}}" $RESOURCE_GROUP dse
#azure group deployment create -f ./opsCenter.json -p "{\"username\": {\"value\": \"datastax\"}, \"password\": {\"value\": \"foo123!\"}, \"region\": {\"value\": \"East Asia\"}}" $RESOURCE_GROUP dse

#azure group deployment create -f ./mainTemplate.json $RESOURCE_GROUP dse
#azure group deployment create -f ./opsCenterNode.json $RESOURCE_GROUP dse

