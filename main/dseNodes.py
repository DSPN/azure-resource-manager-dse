import math


def generate_template(region, nodeSize, numberOfNodes, username, password):
    resources = []
    resources.append(virtualNetworks(region))
    resources.append(networkInterfaces(region))
    resources.append(storageAccounts(region, numberOfNodes))
    resources.append(virtualmachines(region, nodeSize, numberOfNodes, username, password))
    #    return resources
    return []


def virtualNetworks(region):
    return {}


def networkInterfaces(region):
    return {}


def storageAccounts(region, numberOfNodes):
    numberOfStorageAccounts = math.ceil(numberOfNodes / 40.0)
    return {}


# nodesPerRegion number of VMs
def virtualmachines(region, nodeSize, numberOfNodes, username, password):
    for node in range(0, numberOfNodes):
        virtualmachine(region, nodeSize, username, password)
    return []


def virtualmachine(region, nodeSize, username, password):
    return {}
