import json
import opsCenterNode
import dseNodes
import connections

# This python script generates an ARM template that deploys DSE across regions.

with open('clusterParameters.json') as inputFile:
    clusterParameters = json.load(inputFile)

regions = clusterParameters['regions']
nodeSize = clusterParameters['nodeSize']
nodesPerRegion = clusterParameters['nodesPerRegion']
username = clusterParameters['username']
password = clusterParameters['password']

# These parameters are going away as soon as we have a DataStax custom extension for Azure
dataStaxUsername = clusterParameters['dataStaxUsername']
dataStaxPassword = clusterParameters['dataStaxPassword']

# This is the skeleton of the template that we're going to add resources to
generatedTemplate = {
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {},
    "variables": {},
    "resources": [],
    "outputs": {}
}

# Create the OpsCenter node
resources = opsCenterNode.generate_template(username, password, dataStaxUsername, dataStaxPassword)
for resource in resources:
    generatedTemplate['resources'].append(resource)

# Create DSE nodes in each region
for region in regions:
    # This is the 1 in 10.1.0.0.  Not sure if there is a better name for it...
    subnetIndex = regions.index(region) + 1
    resources = dseNodes.generate_template(region, subnetIndex, nodeSize, nodesPerRegion, username, password)
    for resource in resources:
        generatedTemplate['resources'].append(resource)

# Connect the regions together
for region in regions:
    resources = connections.generate_template(region, nodeSize, nodesPerRegion, username, password)
    for resource in resources:
        generatedTemplate['resources'].append(resource)

with open('generatedTemplate.json', 'w') as outputFile:
    json.dump(generatedTemplate, outputFile, sort_keys=True, indent=4, ensure_ascii=False)
