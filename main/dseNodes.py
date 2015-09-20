import math

def generate_template(region, nodeSize, numberOfNodes, username, password):
    resources = []
    resources.append(virtualNetworks)
    resources.append(networkInterfaces)
    resources.append(storageAccounts(numberOfNodes))
    resources.append(virtualmachines(region, nodeSize, numberOfNodes, username, password))

    return []


virtualNetworks = {}
networkInterfaces = {}

def storageAccounts(numberOfNodes):
    numberOfStorageAccounts math.ceil(numberOfNodes/40.0)
    return {}


# nodesPerRegion number of VMs
def virtualmachines(region, nodeSize, numberOfNodes, username, password):
    for node in range(0,numberOfNodes):
        virtualmachine(region, nodeSize, username, password)
    return []

def virtualmachine(region, nodeSize, username, password):
    return {}
