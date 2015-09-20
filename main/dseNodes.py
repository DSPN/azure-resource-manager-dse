import math


def generate_template(region, subnetIndex, nodeSize, numberOfNodes, username, password):
    resources = []

    vnets = virtualNetworks(region, subnetIndex)
    resources.append(vnets)

    for nodeIndex in range(0, numberOfNodes):
        vnetName = vnets['name']
        resources.append(networkInterfaces(region, vnetName, subnetIndex, nodeIndex))

        # resources.append(storageAccounts(region, numberOfNodes))
        # resources.append(virtualmachine(region, nodeSize, username, password))
    return resources


# We want a subnet for the gateways to go in as well as one for any virtual machines.
# 10.x.y.5-255 are usable.
# This gives us 251 usable IPs.
# That will be our maximum number of virtual machines in a region for now as well.
def virtualNetworks(region, subnetIndex):
    return {
        "apiVersion": "2015-06-15",
        "type": "Microsoft.Network/virtualNetworks",
        "name": (region + "_dse_node_vnet").replace(" ", "_").lower(),
        "location": region,
        "properties": {
            "addressSpace": {
                "addressPrefixes": [
                    "10." + str(subnetIndex) + ".0.0/16"
                ]
            },
            "subnets": [
                {
                    "name": "gatewaySubnet",
                    "properties": {
                        "addressPrefix": "10." + str(subnetIndex) + ".0.0/24"
                    }
                },
                {
                    "name": "vmSubnet",
                    "properties": {
                        "addressPrefix": "10." + str(subnetIndex) + ".1.0/24"
                    }
                }
            ]
        }
    }


def networkInterfaces(region, vnetName, subnetIndex, nodeIndex):
    # Usable IPs start at 10.x.y.5
    # At some point we're going to want some logic to deal with more than 255 nodes in a region
    nodeIP = '10.' + str(subnetIndex) + '.1.' + str(nodeIndex+5)

    resource = {
        "apiVersion": "2015-06-15",
        "type": "Microsoft.Network/networkInterfaces",
        "name": "dc" + str(subnetIndex) + "vm" + str(nodeIndex) + "_nic",
        "location": region,
        "dependsOn": [
            "Microsoft.Network/virtualNetworks/" + vnetName
        ],
        "properties": {
            "ipConfigurations": [
                {
                    "name": "ipConfig",
                    "properties": {
                        "privateIPAllocationMethod": "Static",
                        "privateIPAddress": nodeIP,
                        "subnet": {
                            "id": "[concat(resourceId('Microsoft.Network/virtualNetworks', '" + vnetName + "'), '/subnets/vmSubnet')]"
                        }
                    }
                }
            ]
        }
    }
    return resource


def storageAccounts(region, numberOfNodes):
    numberOfStorageAccounts = math.ceil(numberOfNodes / 40.0)
    return None


def virtualmachine(region, nodeSize, username, password):
    return None
