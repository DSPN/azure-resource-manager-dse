import math


def generate_template(region, subnet, nodeSize, numberOfNodes, username, password):
    resources = []
    resources.append(virtualNetworks(region))
    resources.append(networkInterfaces(region))
    resources.append(storageAccounts(region, numberOfNodes))
    resources.append(virtualmachines(region, nodeSize, numberOfNodes, username, password))
    return resources


# We want a subnet for the gateways to go in as well as one for any virtual machines.
# 10.x.y.5-255 are usable.
# This gives us 251 usable IPs.
# That will be our maximum number of virtual machines in a region for now as well.
def virtualNetworks(region):
    return {
        "apiVersion": "2015-06-15",
        "type": "Microsoft.Network/virtualNetworks",
        "name": region + "vnet",
        "location": region,
        "properties": {
            "addressSpace": {
                "addressPrefixes": [
                    "10.0.0.0/16"
                ]
            },
            "subnets": [
                {
                    "name": "gatewaySubnet",
                    "properties": {
                        "addressPrefix": "10.0.0.0/24"
                    }
                },
                {
                    "name": "vmSubnet",
                    "properties": {
                        "addressPrefix": "10.0.1.0/24"
                    }
                }
            ]
        }
    }


def networkInterfaces(region):
    return {}


def storageAccounts(region, numberOfNodes):
    numberOfStorageAccounts = math.ceil(numberOfNodes / 40.0)
    return {}


# nodesPerRegion number of VMs
def virtualmachines(region, nodeSize, numberOfNodes, username, password):
    resources = []
    for node in range(0, numberOfNodes):
        resources.append(virtualmachine(region, nodeSize, username, password))
    return resources


def virtualmachine(region, nodeSize, username, password):
    return {}
