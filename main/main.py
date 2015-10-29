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

# This is the skeleton of the template that we're going to add resources to
generatedTemplate = {
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {},
    "variables": {},
    "resources": [],
    "outputs": {}
}

# Create DSE nodes in each region
for region in regions:
    # This is the 1 in 10.1.0.0 and corresponds to the data center we are deploying to
    # 10.0.x.y is reserved for the OpsCenter resources.
    datacenterIndex = regions.index(region) + 1

    resources = dseNodes.generate_template(region, datacenterIndex, nodeSize, nodesPerRegion, username, password)
    generatedTemplate['resources'] += resources

# Connect the regions together
resources = connections.generate_template(regions)
generatedTemplate['resources'] += resources

# Create the OpsCenter node
resources = opsCenterNode.generate_template(clusterParameters)
generatedTemplate['resources'] += resources

with open('generatedTemplate.json', 'w') as outputFile:
    json.dump(generatedTemplate, outputFile, sort_keys=True, indent=4, ensure_ascii=False)
