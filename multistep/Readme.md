

# 1: Create Resource Group and vnet

```
azure group create mock "eastus"
azure group deployment create -f  template-mock-vnet.json mock
```

# 2: Deploy OpsCenter
