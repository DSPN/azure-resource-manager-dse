def generate_template(username, password, dataStaxUsername, dataStaxPassword):
    # We're going to create all these resources in resourceGroup().location
    # The OpsCenter node always has private IP 10.0.1.5

    resources = []
    resources.append(virtualNetworks)
    resources.append(networkSecurityGroups)
    resources.append(publicIPAddresses)
    resources.append(networkInterfaces)
    resources.append(storageAccounts)
    resources.append(virtualmachines(username, password))
    resources.append(extension(username, password, dataStaxUsername, dataStaxPassword))
    return resources


# We want a subnet for the gateways to go in as well as one for any virtual machines.
# 10.x.y.5-255 are usable.
# This gives us 251 usable IPs.
# That will be our maximum number of virtual machines in a region for now as well.
virtualNetworks = {
    "apiVersion": "2015-06-15",
    "type": "Microsoft.Network/virtualNetworks",
    "name": "opscentervnet",
    "location": "[resourceGroup().location]",
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

networkSecurityGroups = {
    "apiVersion": "2015-06-15",
    "type": "Microsoft.Network/networkSecurityGroups",
    "name": "securityGroup",
    "location": "[resourceGroup().location]",
    "properties": {
        "securityRules": [
            {
                "name": "SSH",
                "properties": {
                    "description": "Allows SSH traffic",
                    "protocol": "Tcp",
                    "sourcePortRange": "22",
                    "destinationPortRange": "22",
                    "sourceAddressPrefix": "*",
                    "destinationAddressPrefix": "*",
                    "access": "Allow",
                    "priority": 100,
                    "direction": "Inbound"
                }
            },
            {
                "name": "HTTP",
                "properties": {
                    "description": "Allows HTTP traffic",
                    "protocol": "Tcp",
                    "sourcePortRange": "8888",
                    "destinationPortRange": "8888",
                    "sourceAddressPrefix": "*",
                    "destinationAddressPrefix": "*",
                    "access": "Allow",
                    "priority": 110,
                    "direction": "Inbound"
                }
            },
            {
                "name": "HTTPS",
                "properties": {
                    "description": "Allows HTTPS traffic",
                    "protocol": "Tcp",
                    "sourcePortRange": "8443",
                    "destinationPortRange": "8443",
                    "sourceAddressPrefix": "*",
                    "destinationAddressPrefix": "*",
                    "access": "Allow",
                    "priority": 120,
                    "direction": "Inbound"
                }
            }
        ]
    }
}

publicIPAddresses = {
    "apiVersion": "2015-06-15",
    "type": "Microsoft.Network/publicIPAddresses",
    "name": "publicIP",
    "location": "[resourceGroup().location]",
    "properties": {
        "publicIPAllocationMethod": "Dynamic",
        "dnsSettings": {
            "domainNameLabel": "[resourceGroup().name]"
        }
    }
}

networkInterfaces = {
    "apiVersion": "2015-06-15",
    "type": "Microsoft.Network/networkInterfaces",
    "name": "networkInterface",
    "location": "[resourceGroup().location]",
    "dependsOn": [
        "Microsoft.Network/publicIPAddresses/publicIP",
        "Microsoft.Network/networkSecurityGroups/securityGroup"
    ],
    "properties": {
        "ipConfigurations": [
            {
                "name": "ipConfig",
                "properties": {
                    "publicIPAddress": {
                        "id": "[resourceId('Microsoft.Network/publicIPAddresses','publicIP')]"
                    },
                    "privateIPAllocationMethod": "Static",
                    "privateIPAddress": "10.0.1.5",
                    "subnet": {
                        "id": "[concat(resourceId('Microsoft.Network/virtualNetworks', 'opscentervnet'), '/subnets/vmSubnet')]"
                    },
                    "networkSecurityGroup": {
                        "id": "[resourceId('Microsoft.Network/networkSecurityGroups','securityGroup')]"
                    }
                }
            }
        ]
    }
}

storageAccounts = {
    "apiVersion": "2015-05-01-preview",
    "type": "Microsoft.Storage/storageAccounts",
    "name": "[concat('opscsa',resourceGroup().name)]",
    "location": "[resourceGroup().location]",
    "properties": {
        "accountType": "Standard_LRS"
    }
}


def virtualmachines(username, password):
    return {
        "apiVersion": "2015-06-15",
        "type": "Microsoft.Compute/virtualMachines",
        "name": "opscentervm",
        "location": "[resourceGroup().location]",
        "dependsOn": [
            "Microsoft.Network/networkInterfaces/networkInterface",
            "[concat('Microsoft.Storage/storageAccounts/opscsa',resourceGroup().name)]"
        ],
        "properties": {
            "hardwareProfile": {
                "vmSize": "Standard_A1"
            },
            "osProfile": {
                "computername": "opscenter",
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
                        "uri": "[concat('http://opscsa',resourceGroup().name,'.blob.core.windows.net/vhds/opscentervm-osdisk.vhd')]"
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


def extension(username, password, dataStaxUsername, dataStaxPassword):
    return {
        "type": "Microsoft.Compute/virtualMachines/extensions",
        "name": "opscentervm/installopscenter",
        "apiVersion": "2015-06-15",
        "location": "[resourceGroup().location]",
        "dependsOn": [
            "Microsoft.Compute/virtualMachines/opscentervm"
        ],
        "properties": {
            "publisher": "Microsoft.OSTCExtensions",
            "type": "CustomScriptForLinux",
            "typeHandlerVersion": "1.3",
            "settings": {
                "fileUris": [
                    "https://raw.githubusercontent.com/DSPN/azure-resource-manager-dse/master/main/scripts/opsCenter.sh",
                    "https://raw.githubusercontent.com/DSPN/azure-resource-manager-dse/master/main/scripts/installJava.sh",
                    "https://raw.githubusercontent.com/DSPN/azure-resource-manager-dse/master/main/scripts/configureOpsCenter.sh",
                    "https://raw.githubusercontent.com/DSPN/azure-resource-manager-dse/master/main/scripts/turnOnOpsCenterAuth.sh"
                ],
                "commandToExecute": "bash opsCenter.sh " + username + " " + password + " " + dataStaxUsername + " " + dataStaxPassword
            }
        }
    }
