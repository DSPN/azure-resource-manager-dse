import math


def generate_template(region, datacenterIndex, nodeSize, numberOfNodes, username, password):
    resources = []

    vnets = virtualNetworks(region, datacenterIndex)
    resources.append(vnets)

    for nodeIndex in range(0, numberOfNodes):
        vnetName = vnets['name']
        resources.append(networkInterfaces(region, vnetName, datacenterIndex, nodeIndex))

        storageAccountIndex = int(math.floor(nodeIndex / 40.0))
        # Check if we've attached 40 drives to the current storage account.  If so, we'll need to make a new one.
        if (nodeIndex % 40) == 0:
            resources.append(storageAccounts(region, datacenterIndex, storageAccountIndex))

            # resources.append(virtualmachine(region, nodeSize, username, password))
    return resources


# We want a subnet for the gateways to go in as well as one for any virtual machines.
# 10.x.y.5-255 are usable.
# This gives us 251 usable IPs.
# That will be our maximum number of virtual machines in a region for now as well.
def virtualNetworks(region, datacenterIndex):
    return {
        "apiVersion": "2015-06-15",
        "type": "Microsoft.Network/virtualNetworks",
        "name": (region + "_dse_node_vnet").replace(" ", "_").lower(),
        "location": region,
        "properties": {
            "addressSpace": {
                "addressPrefixes": [
                    "10." + str(datacenterIndex) + ".0.0/16"
                ]
            },
            "subnets": [
                {
                    "name": "gatewaySubnet",
                    "properties": {
                        "addressPrefix": "10." + str(datacenterIndex) + ".0.0/24"
                    }
                },
                {
                    "name": "vmSubnet",
                    "properties": {
                        "addressPrefix": "10." + str(datacenterIndex) + ".1.0/24"
                    }
                }
            ]
        }
    }


def networkInterfaces(region, vnetName, datacenterIndex, nodeIndex):
    # Usable IPs start at 10.x.y.5
    # At some point we're going to want some logic to deal with more than 255 nodes in a region
    nodeIP = '10.' + str(datacenterIndex) + '.1.' + str(nodeIndex + 5)

    resource = {
        "apiVersion": "2015-06-15",
        "type": "Microsoft.Network/networkInterfaces",
        "name": "dc" + str(datacenterIndex) + "vm" + str(nodeIndex) + "_nic",
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


def storageAccounts(region, datacenterIndex, storageAccountIndex):
    resource = {
        "apiVersion": "2015-05-01-preview",
        "type": "Microsoft.Storage/storageAccounts",
        "name": "dc" + str(datacenterIndex) + "sa" + str(storageAccountIndex),
        "location": region,
        "properties": {
            "accountType": "Standard_LRS"
        }
    }

    return resource


def virtualmachine(region, nodeSize, username, password):
    return None
