import math


def generate_template(region, datacenterIndex, nodeSize, numberOfNodes, username, password):
    resources = []

    vnet = virtualNetworks(region, datacenterIndex)
    resources.append(vnet)
    vnetName = vnet['name']

    for nodeIndex in range(0, numberOfNodes):
        nic = networkInterfaces(region, vnetName, datacenterIndex, nodeIndex)
        resources.append(nic)
        nicName = nic['name']

        storageAccountIndex = int(math.floor(nodeIndex / 40.0))
        # Check if we've attached 40 drives to the current storage account.  If so, we'll need to make a new one.
        if (nodeIndex % 40) == 0:
            sa = storageAccounts(region, datacenterIndex, storageAccountIndex)
            resources.append(sa)
            saName = sa['name']

        resources.append(virtualmachines(region, nodeSize, username, password, datacenterIndex, nodeIndex, saName, nicName))
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


def virtualmachines(region, nodeSize, username, password, datacenterIndex, nodeIndex, storageAccountName, nicName):
    computerName = "dc" + str(datacenterIndex) + "vm" + str(nodeIndex)
    virtualMachineName = computerName + "vm"

    resources = {
        "apiVersion": "2015-06-15",
        "type": "Microsoft.Compute/virtualMachines",
        "name": virtualMachineName,
        "location": region,
        "dependsOn": [
            "Microsoft.Network/networkInterfaces/" + nicName,
            "Microsoft.Storage/storageAccounts/" + storageAccountName
        ],
        "properties": {
            "hardwareProfile": {
                "vmSize": nodeSize
            },
            "osProfile": {
                "computername": computerName,
                "adminUsername": username,
                "adminPassword": password
            },
            "storageProfile": {
                "imageReference": {
                    "publisher": "Canonical",
                    "offer": "UbuntuServer",
                    "sku": "14.04.2-LTS",
                    "version": "latest"
                },
                "osDisk": {
                    "name": "osdisk",
                    "vhd": {
                        "uri": "http://" + storageAccountName + ".blob.core.windows.net/vhds/" + virtualMachineName + "-osdisk.vhd"
                    },
                    "caching": "ReadWrite",
                    "createOption": "FromImage"
                }
            },
            "networkProfile": {
                "networkInterfaces": [
                    {
                        "id": "[resourceId('Microsoft.Network/networkInterfaces','networkInterface')]"
                    }
                ]
            }
        }
    }
    return resources
