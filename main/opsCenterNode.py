def generate_template(username, password, datastaxUsername, datastaxPassword):
    resources = []
    resources.append(virtualNetworks)
    resources.append(networkSecurityGroups)
    resources.append(publicIPAddresses)
    resources.append(networkInterfaces)
    resources.append(storageAccounts)
    resources.append(virtualMachines)

    return resources

virtualNetworks = {
    "apiVersion": "2015-06-15",
    "type": "Microsoft.Network/virtualNetworks",
    "name": "vnet",
    "location": "[parameters('region')]",
    "properties": {
        "addressSpace": {
            "addressPrefixes": [
                "10.0.0.0/16"
            ]
        },
        "subnets": [
            {
                "name": "subnet0",
                "properties": {
                    "addressPrefix": "10.0.0.0/24"
                }
            },
            {
                "name": "subnet1",
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
    "location": "[parameters('region')]",
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
    "location": "[parameters('region')]",
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
    "location": "[parameters('region')]",
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
                    "privateIPAddress": "10.0.0.6",
                    "subnet": {
                        "id": "[concat(resourceId('Microsoft.Network/virtualNetworks', 'vnet'), '/subnets/', 'subnet0')]"
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
    "name": "[concat('opscenter',resourceGroup().name)]",
    "location": "[parameters('region')]",
    "properties": {
        "accountType": "Standard_LRS"
    }
}

virtualMachines = {
    "apiVersion": "2015-06-15",
    "type": "Microsoft.Compute/virtualMachines",
    "name": "opscenter",
    "location": "[parameters('region')]",
    "dependsOn": [
        "Microsoft.Network/networkInterfaces/networkInterface"
    ],
    "properties": {
        "hardwareProfile": {
            "vmSize": "Standard_A1"
        },
        "osProfile": {
            "computername": "opscenter",
            "adminUsername": "[parameters('username')]",
            "adminPassword": "[parameters('password')]"
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
                    "uri": "[concat('http://opscenter',resourceGroup().name,'.blob.core.windows.net/vhds/opscentervm-osdisk.vhd')]"
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
