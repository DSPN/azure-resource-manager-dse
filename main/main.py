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

# This is the skeleton of the template that we're going to add resources to
generatedTemplate = {
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "resources": [
    ]
}

# First we create the infrastructure that the OpsCenter node requires:
resources = opsCenterNode.generate_template(username, password, datastaxUsername, datastaxPassword)
for resource in resources:
    generatedTemplate['resources'].append(resource)

# Then we loop through for each region and create nodes in them:
for region in regions:
    resources = dseNodes.generate_template(region, nodeSize, nodesPerRegion, username, password)
    for resource in resources:
        generatedTemplate['resources'].append(resource)

# Then we loop across the Vnets (OpsCenter and the DSE nodes) and connect those all togther.  This requires creating:
for region in regions:
    resources = connections.generate_template(region, nodeSize, nodesPerRegion, username, password)
    for resource in resources:
        generatedTemplate['resources'].append(resource)

with open('generatedTemplate.json', 'w') as outputFile:
    json.dump(generatedTemplate, outputFile, sort_keys=True, indent=4, ensure_ascii=False)
