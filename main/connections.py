def generate_template(region, nodeSize, nodesPerRegion, username, password):
    return []


resources = [
    {
        "name": "[parameters('virtualNetworkName1')]",
        "type": "Microsoft.Network/virtualNetworks",
        "location": "[parameters('location1')]",
        "apiVersion": "2015-05-01-preview",
        "properties": {
            "addressSpace": {
                "addressPrefixes": [
                    "[parameters('virtualNetworkAddressRange1')]"
                ]
            },
            "subnets": "[parameters('subnets1')]"
        }
    },
    {
        "name": "[parameters('virtualNetworkName2')]",
        "type": "Microsoft.Network/virtualNetworks",
        "location": "[parameters('location2')]",
        "apiVersion": "2015-05-01-preview",
        "properties": {
            "addressSpace": {
                "addressPrefixes": [
                    "[parameters('virtualNetworkAddressRange2')]"
                ]
            },
            "subnets": "[parameters('subnets2')]"
        }
    },
    {
        "apiVersion": "2015-05-01-preview",
        "type": "Microsoft.Network/publicIPAddresses",
        "name": "GWIPAddress1",
        "location": "[parameters('location1')]",
        "properties": {
            "publicIPAllocationMethod": "Dynamic"
        }
    },
    {
        "apiVersion": "2015-05-01-preview",
        "type": "Microsoft.Network/publicIPAddresses",
        "name": "GWIPAddress2",
        "location": "[parameters('location2')]",
        "properties": {
            "publicIPAllocationMethod": "Dynamic"
        }
    },
    {
        "apiVersion": "2015-05-01-preview",
        "type": "Microsoft.Network/virtualNetworkGateways",
        "name": "[parameters('gatewayName1')]",
        "location": "[parameters('location1')]",
        "dependsOn": [
            "Microsoft.Network/publicIPAddresses/GWIPAddress1",
            "[concat('Microsoft.Network/virtualNetworks/', parameters('virtualNetworkName1'))]"
        ],
        "properties": {
            "ipConfigurations": [
                {
                    "properties": {
                        "privateIPAllocationMethod": "Dynamic",
                        "subnet": {
                            "id": "[variables('gwSubnetRef1')]"
                        },
                        "publicIPAddress": {
                            "id": "[resourceId('Microsoft.Network/publicIPAddresses','GWIPAddress1')]"
                        }
                    },
                    "name": "vnetGatewayConfig"
                }
            ],
            "gatewayType": "Vpn",
            "vpnType": "RouteBased",
            "enableBgp": false
        }
    },
    {
        "apiVersion": "2015-05-01-preview",
        "type": "Microsoft.Network/virtualNetworkGateways",
        "name": "[parameters('gatewayName2')]",
        "location": "[parameters('location2')]",
        "dependsOn": [
            "Microsoft.Network/publicIPAddresses/GWIPAddress2",
            "[concat('Microsoft.Network/virtualNetworks/', parameters('virtualNetworkName2'))]"
        ],
        "properties": {
            "ipConfigurations": [
                {
                    "properties": {
                        "privateIPAllocationMethod": "Dynamic",
                        "subnet": {
                            "id": "[variables('gwSubnetRef2')]"
                        },
                        "publicIPAddress": {
                            "id": "[resourceId('Microsoft.Network/publicIPAddresses','GWIPAddress2')]"
                        }
                    },
                    "name": "vnetGatewayConfig"
                }
            ],
            "gatewayType": "Vpn",
            "vpnType": "RouteBased",
            "enableBgp": false
        }
    },
    {
        "apiVersion": "2015-05-01-preview",
        "type": "Microsoft.Network/connections",
        "name": "connection1",
        "location": "[parameters('location1')]",
        "dependsOn": [
            "[concat('Microsoft.Network/virtualNetworkGateways/', parameters('gatewayName1'))]",
            "[concat('Microsoft.Network/virtualNetworkGateways/', parameters('gatewayName2'))]"
        ],
        "properties": {
            "virtualNetworkGateway1": {
                "id": "[variables('vnetGatewayID1')]"
            },
            "virtualNetworkGateway2": {
                "id": "[variables('vnetGatewayID2')]"
            },
            "connectionType": "Vnet2Vnet",
            "routingWeight": 3,
            "sharedKey": "[parameters('gatewaySharedKey')]"
        }
    },
    {
        "apiVersion": "2015-05-01-preview",
        "type": "Microsoft.Network/connections",
        "name": "connection2",
        "location": "[parameters('location2')]",
        "dependsOn": [
            "[concat('Microsoft.Network/virtualNetworkGateways/', parameters('gatewayName1'))]",
            "[concat('Microsoft.Network/virtualNetworkGateways/', parameters('gatewayName2'))]"
        ],
        "properties": {
            "virtualNetworkGateway1": {
                "id": "[variables('vnetGatewayID2')]"
            },
            "virtualNetworkGateway2": {
                "id": "[variables('vnetGatewayID1')]"
            },
            "connectionType": "Vnet2Vnet",
            "routingWeight": 3,
            "sharedKey": "[parameters('gatewaySharedKey')]"
        }
    }
]
