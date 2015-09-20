#/bin/sh

RESOURCE_GROUP=$1
azure group create $RESOURCE_GROUP "East Asia"

# This writes output to generatedTemplate.json
python main.py

#azure group deployment create -f ./generatedTemplate.json $RESOURCE_GROUP dse



#########
### old
#########

#azure group deployment create -f ./vnet.json -p "{\"region\": {\"value\": \"East Asia\"}}" $RESOURCE_GROUP dse
#azure group deployment create -f ./opsCenter.json -p "{\"username\": {\"value\": \"datastax\"}, \"password\": {\"value\": \"foo123!\"}, \"region\": {\"value\": \"East Asia\"}}" $RESOURCE_GROUP dse

#azure group deployment create -f ./mainTemplate.json $RESOURCE_GROUP dse
#azure group deployment create -f ./opsCenterNode.json $RESOURCE_GROUP dse

