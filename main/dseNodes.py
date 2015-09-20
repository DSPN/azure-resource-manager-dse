def generate_template(region, nodeSize, nodesPerRegion, username, password):
    resources = []
    resources.append(virtualNetworks)
    resources.append(networkInterfaces)
    resources.append(storageAccounts)
    resources.append(virtualmachines(username, password))

    return []


virtualNetworks = {}
networkInterfaces = {}

# math.ceil(nodesPerRegion/40.0) number of storage accounts
storageAccounts = {}


# nodesPerRegion number of VMs
def virtualmachines(username, password):
    return {}
