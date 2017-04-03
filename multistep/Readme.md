# Multistep templates to deploy a DSE cluster
These templates are similar to the singledc templates, but have been separated into pieces to allow for more flexibility. They can be used deploy a DSE cluster in an existing resource group or vnet, deploy a cluster with a single datacenter, multiple datacenters, or multiple distinct clusters. This is also a beta version and bugs most likely exist.

## 1: Create Resource Group and vnet
The DSE cluster needs to be deployed into a resource group, vnet, and subnet. If these already exist, skip this step. **Note:** the later example commands and the parameter files reference `mock, mock-vnet, mock-subnet, location`. If skipping this step be sure to change these parameters to the appropriate values.
```
azure group create mock "eastus" && \
azure group deployment create -f  template-mock-vnet.json mock
```

## 2: Deploy OpsCenter
The template file `template-opscenter.json` performs 2 things:
- Deploys a VM running OpsCenter
- Creates in OpsCenter's LifeCycleManager (LCM) several objects:
  - An empty cluster, using the `clusterName` parameter
  - Default config profile
  - SSH credentials for install/config of node VMs, using the `adminUsername/adminPassword` parameters
  - Adds DSE's apt repo  

Run the below command to deploy:
```
azure group deployment create -f template-opscenter.json -e parameters-opscenter.json mock
```
Allow command to finish before proceeding to the next step. Once the command completes this template has one output: `lifecycleManagerURL`, which goes to the LCM web console in OpsCenter.

## 3: Deploy nodes
**Note:** parameters that appear in both `template-opscenter.json` and `template-nodes.json` **must** match.

The template file `template-nodes.json` will:
- Deploy `nodeCount` VM's as DSE nodes
- Add these nodes to the cluster `clusterName`
- Trigger an LCM install job when the last VM comes up

Run the below command to deploy:
```
azure group deployment create -f template-nodes.json -e parameters-nodes.json mock
info:    Executing command group deployment create
info:    Supply values for the following parameters
opsCenterIP:  10.0.0.4
clusterName:  prodCluster
namespace:  dc0
```
Here we can see there are 3 parameters not in the parameter file, so the CLI prompts for input
  - `opsCenterIP`:  can be either the private or public ip of the OpsCenter VM
  - `clusterName`:  must match the value passed to `template-opscenter.json`
  - `namespace`:  **important** this parameter serves as both the name of the datacenter the nodes belong to *and* a prefix for the names of node VM's. Because it is used as a prefix this can only contain lowercase letters and numbers, no symbols.

The progress of the LCM install job can be monitored in the LCM web console.

## 3: Optionally deploy additional datacenter or cluster
### New datacenter
If deploying an additional datacenter in the same cluster, rerun the previous command but:
- add a deployment name (here `nodes2`), this avoids reusing `template-nodes` as a deployment name
- give a different value for `namespace`

```
azure group deployment create -f template-nodes.json -e parameters-nodes.json mock nodes2
info:    Executing command group deployment create
info:    Supply values for the following parameters
opsCenterIP:  10.0.0.4
clusterName:  prodCluster
namespace:  dc1
```
### New cluster
If you want to deploy nodes to a 2nd cluster, first create a new cluster in the LCM console by clicking on the *Clusters* tab and then the plus sign above the column of clusters. Choose a new cluster name (eg `devCluster`) and the default credentials, config profile, and repo. Rerun the same command changing the deployment name (here `nodes3`) and choosing a new and **unique** value for the `namespace` parameter, eg here we pass in `devdc0` since `dc0` has been used previously. Using a non-unique value will result in namespace collisions when trying to create VM's.

```
azure group deployment create -f template-nodes.json -e parameters-nodes.json mock nodes3
info:    Executing command group deployment create
info:    Supply values for the following parameters
opsCenterIP:  10.0.0.4
clusterName:  devCluster
namespace:  devdc0
```
