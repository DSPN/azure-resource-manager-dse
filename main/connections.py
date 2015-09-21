def generate_template(regions):
    resources = []

    # Create a public IP for each gateway
    publicIPName = "opsc_gateway_ip"
    resources.append(publicIPAddresses("[resourceGroup().location]", publicIPName))
    vnetName = "opscentervnet"
    resources.append(virtualNetworkGateways("[resourceGroup().location]", "opsc_gateway", publicIPName, vnetName))

    for region in regions:
        datacenterIndex = regions.index(region) + 1

        publicIPName = "dsenode_gw_ip_dc" + str(datacenterIndex)
        resources.append(publicIPAddresses(region, publicIPName))
        vnetName = (region + "_dse_node_vnet").replace(" ", "_").lower()
        resources.append(virtualNetworkGateways(region, "dseNode_gw_dc" + str(datacenterIndex), publicIPName, vnetName))

    return resources


def publicIPAddresses(region, name):
    return {
        "apiVersion": "2015-05-01-preview",
        "type": "Microsoft.Network/publicIPAddresses",
        "name": name,
        "location": region,
        "properties": {
            "publicIPAllocationMethod": "Dynamic"
        }
    }


def virtualNetworkGateways(region, name, publicIPName, vnetName):
    return {
        "apiVersion": "2015-05-01-preview",
        "type": "Microsoft.Network/virtualNetworkGateways",
        "name": name,
        "location": region,
        "dependsOn": [
            "Microsoft.Network/publicIPAddresses/" + publicIPName,
            "Microsoft.Network/virtualNetworks/" + vnetName
        ],
        "properties": {
            "ipConfigurations": [
                {
                    "properties": {
                        "privateIPAllocationMethod": "Dynamic",
                        "subnet": {
                            "id": "gatewaySubnet"
                        },
                        "publicIPAddress": {
                            "id": "[resourceId('Microsoft.Network/publicIPAddresses','" + publicIPName + "')]"
                        }
                    },
                    "name": "vnetGatewayConfig"
                }
            ],
            "gatewayType": "Vpn",
            "vpnType": "RouteBased",
            "enableBgp": False
        }
    }


def connections():
    return {
        "apiVersion": "2015-05-01-preview",
        "type": "Microsoft.Network/connections",
        "name": "connection2",
        "location": "[parameters('location2')]",
        "dependsOn": [
            "Microsoft.Network/virtualNetworkGateways/gw1",
            "Microsoft.Network/virtualNetworkGateways/gw2"
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
            "sharedKey": "abc123"
        }
    }
