import json
import opsCenterNode
import dseNodes
import connections
from pprint import pprint

# This python script generates an ARM template that deploys DSE across regions.
# Arguments are passed in as a json file.

with open('clusterParameters.json') as inputFile:
    clusterParameters = json.load(inputFile)

regions = clusterParameters['regions']
nodeSize = clusterParameters['nodeSize']
nodesPerRegion = clusterParameters['nodesPerRegion']
username = clusterParameters['username']
password = clusterParameters['password']

# These parameters are going away as soon as we have a DataStax custom extension for Azure
datastaxUsername = clusterParameters['datastaxUsername']
datastaxPassword = clusterParameters['datastaxPassword']

# First we create the infrastructure that the OpsCenter node requires:
opsCenterNode.generate_template(username, password, datastaxUsername, datastaxPassword)

# Then we loop through for each region and create nodes in them:
for region in regions:
    dseNodes.generate_template(region, nodeSize, nodesPerRegion, username, password)

# Then we loop across the Vnets (OpsCenter and the DSE nodes) and connect those all togther.  This requires creating:
for region in regions:
    connections.generate_template(region, nodeSize, nodesPerRegion, username, password)
