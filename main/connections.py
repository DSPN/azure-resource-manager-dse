def generate_template(locations):
    resources = []

    # Create a public IP for each gateway
    publicIPName = "opsc_gateway_ip"
    resources.append(publicIPAddresses("[resourceGroup().location]", publicIPName))
    vnetName = "opscentervnet"
    resources.append(virtualNetworkGateways("[resourceGroup().location]", "opsc_gateway", publicIPName, vnetName))

    for location in locations:
        datacenterIndex = locations.index(location) + 1

        publicIPName = "dsenode_gw_ip_dc" + str(datacenterIndex)
        resources.append(publicIPAddresses(location, publicIPName))
        vnetName = (location + "_dse_node_vnet").replace(" ", "_").lower()
        gatewayName = "dseNode_gw_dc" + str(datacenterIndex)
        resources.append(virtualNetworkGateways(location, gatewayName, publicIPName, vnetName))

        # Create connections in both directions between OpsCenter and the Nodes
        resources.append(connections("[resourceGroup().location]", "opsc_gateway", gatewayName))
        resources.append(connections(location, gatewayName, "opsc_gateway"))

    # Connect the nodes
    for locationA in locations:
        datacenterIndexA = locations.index(locationA) + 1
        gatewayNameA = "dseNode_gw_dc" + str(datacenterIndexA)

        for locationB in locations:
            datacenterIndexB = locations.index(locationB) + 1
            gatewayNameB = "dseNode_gw_dc" + str(datacenterIndexB)

            if datacenterIndexA == datacenterIndexB:
                pass
            else:
                resources.append(connections(locationA, gatewayNameA, gatewayNameB))

    return resources


def publicIPAddresses(location, name):
    return {
        "apiVersion": "2015-05-01-preview",
        "type": "Microsoft.Network/publicIPAddresses",
        "name": name,
        "location": location,
        "properties": {
            "publicIPAllocationMethod": "Dynamic"
        }
    }


def virtualNetworkGateways(location, gatewayName, publicIPName, vnetName):
    return {
        "apiVersion": "2015-05-01-preview",
        "type": "Microsoft.Network/virtualNetworkGateways",
        "name": gatewayName,
        "location": location,
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
                            "id": "[concat(resourceId('Microsoft.Network/virtualNetworks', '" + vnetName + "'),'/subnets/gatewaySubnet')]"
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


def connections(location, gateway1Name, gateway2Name):
    return {
        "apiVersion": "2015-05-01-preview",
        "type": "Microsoft.Network/connections",
        "name": "connection_" + gateway1Name + "_" + gateway2Name,
        "location": location,
        "dependsOn": [
            "Microsoft.Network/virtualNetworkGateways/" + gateway1Name,
            "Microsoft.Network/virtualNetworkGateways/" + gateway2Name
        ],
        "properties": {
            "virtualNetworkGateway1": {
                "id": "[resourceId('Microsoft.Network/virtualNetworkGateways','" + gateway1Name + "')]"
            },
            "virtualNetworkGateway2": {
                "id": "[resourceId('Microsoft.Network/virtualNetworkGateways','" + gateway2Name + "')]"
            },
            "connectionType": "Vnet2Vnet",
            "routingWeight": 3,
            "sharedKey": "abc123"
        }
    }
