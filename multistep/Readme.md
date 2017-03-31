

# 1: Create Resource Group and vnet

```
azure group create mock "eastus" && \
azure group deployment create -f  template-mock-vnet.json mock
```

# 2: Deploy OpsCenter

```
azure group deployment create -f template-opscenter.json -e parameters-opscenter.json mock
```

# 3: Deploy nodes

```
azure group deployment create -f template-nodes.json -e parameters-nodes.json mock
```

sleep 10m
azure group create mock "eastus" && \
azure group deployment create -f  template-mock-vnet.json mock && \
azure group deployment create -f template-opscenter.json -e parameters-opscenter.json mock

azure group deployment create -f template-nodes.json -e parameters-nodes.json mock

azure group deployment create -f template-nodes.json -e parameters-nodes2.json mock template-nodes2
