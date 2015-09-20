import math


def generate_template(region, subnetIndex, nodeSize, numberOfNodes, username, password):
    resources = []
    resources.append(virtualNetworks(region, subnetIndex))

    for node in range(0, numberOfNodes):
        resources.append(networkInterfaces(region))
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


def networkInterfaces(region):
    return  = {
        "apiVersion": "2015-06-15",
        "type": "Microsoft.Network/networkInterfaces",
        "name": "networkInterface",
        "location": region,
        "dependsOn": [
            "Microsoft.Network/publicIPAddresses/publicIP",
            "Microsoft.Network/networkSecurityGroups/securityGroup"
        ],
        "properties": {
            "ipConfigurations": [
                {
                    "name": "ipConfig",
                    "properties": {
                        "privateIPAllocationMethod": "Static",
                        "privateIPAddress": "10.0.1.5",
                        "subnet": {
                            "id": "[concat(resourceId('Microsoft.Network/virtualNetworks', 'opscentervnet'), '/subnets/vmSubnet')]"
                        }
                    }
                }
            ]
        }
    }


def storageAccounts(region, numberOfNodes):
    numberOfStorageAccounts = math.ceil(numberOfNodes / 40.0)
    return None


def virtualmachine(region, nodeSize, username, password):
    return None
