# Multistep templates to deploy a DSE cluster
These templates are similar to the singledc templates, but have been separated into pieces to allow for more flexibility. They can be used deploy a DSE cluster in an existing resource group or vnet, deploy a cluster with a single datacenter, multiple datacenters, or multiple distinct clusters. This is also a beta version and bugs most likely exist.


## 1: Create Resource Group and vnet
The DSE cluster needs to be deployed into a resource group, vnet, and subnet. If these already exist, skip this step. **Note:** the later example commands and the parameter files reference the resource group, vnet, subnet and location. If skipping this step be sure to change these parameters to the appropriate values.
```
az group create --name mock --location "eastus"
az group deployment create \
--resource-group mock \
--template-file template-vnet.json \
--parameters @parameters-vnet.json \
--verbose
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
az group deployment create \
--resource-group mock \
--template-file template-opscenter.json \
--parameters @parameters-opscenter.json \
--verbose
```
Allow command to finish before proceeding to the next step. Once the command completes this template has one output: `lifecycleManagerURL`, which goes to the LCM web console in OpsCenter.

## 3: Deploy nodes
**Note:** parameters that appear in both `template-opscenter.json` and `template-nodes.json` **must** match.

The template file `template-nodes.json` will:
- Deploy `nodeCount` VM's as DSE nodes
- Add these nodes to the cluster `clusterName`

Run the below command to deploy:
```
az group deployment create \
--resource-group mock \
--template-file template-nodes.json \
--parameters @parameters-nodes.json \
--verbose
```
There are 2 parameters in the parameter file that may be non-obvious:
  - `opsCenterIP`:  can be either the private or public ip of the OpsCenter VM
  - `namespace`:  **important** this parameter serves as both the name of the datacenter the nodes belong to *and* a prefix for the names of node VM's. Because it is used as a prefix this can only contain lowercase letters and numbers, no symbols.

The progress of the LCM install job can be monitored in the LCM web console.

## 4: Optionally deploy additional datacenter or cluster
### New datacenter
If deploying an additional datacenter in the same cluster, copy the parameters file, give a different value for `namespace`, eg `dc1`, rerun the previous command.

If you want to deploy the second datacenter to a **different region** you must also:
- deploy a second vnet in that region
- set the `location, vnet, subnet` parameters correctly
- set the `opsCenterIP` to be the **public ip of the OpsCenter instance**. If this is not set correctly the vm's must be deleted before redeploying.
- run the command below

```
az group deployment create \
--resource-group mock \
--template-file template-nodes.json \
--parameters @parameters-nodes2.json \
--name nodes2 \
--verbose
```

### Post-deploy

Once all datacenters have been created you need to open the `lifecycleManagerURL` in a browser and run a cluster level install job.

Once the install is finished and the cluster has been created the following operations should be performed:
- Appropriate [firewall rules](https://docs.datastax.com/en/dse/5.1/dse-admin/datastax_enterprise/security/secFirewallPorts.html?hl=ports) should be set.
- [Https](https://docs.datastax.com/en/opscenter/6.1/opsc/configure/opscConfiguringEnablingHttps_t.html) and [auth](https://docs.datastax.com/en/opscenter/6.1/opsc/configure/opscEnablingAuth.html) should be turned on for OpsCenter.
-The system keyspaces should be set to use NetworkTopology strategy.


Run the command below locally, or on the OpsCenter vm. The `strategy_options` field must contain the correct datacenter names.
Note: null return on curl calls indicates no error.
```
OPSC="40.121.208.254"
# leaving out system and system_schema (local replication)
keyspaces="system_auth system_distributed system_traces dse_security dse_perf dse_leases dse_system cfs_archive spark_system cfs solr_admin dsefs OpsCenter HiveMetaStore"

for ks in $keyspaces; do
  echo "ALTER KEYSPACE "$ks"..."
  msg=$(curl -s -X PUT http://$OPSC:8888/testCluster/keyspaces/$ks -d '{
    "strategy_class": "NetworkTopologyStrategy",
    "strategy_options": {"dc0": "3", "dc1": "3"},
    "durable_writes": true
  }')
  echo "Return: "$msg
done
```

Finally https and auth can be turned on for OpsCenter, there is a script one can run on the OpsC vm:
```
jcp@tenkara:multistep$ ssh datastax@40.121.208.254
......
datastax@opscenter:/tmp$ sudo bash
root@opscenter:/tmp# cd /var/lib/waagent/Microsoft.OSTCExtensions.CustomScriptForLinux-1.5.2.1/download/0/install-datastax-ubuntu-5.5.6/bin/opscenter/
root@opscenter:# ./set_opsc_pw_https.sh somepassword
Turn on OpsC auth
Turn on SSL
Restart OpsC
Connect to OpsC after restart...
Attempt 1...
Attempt 2...
Attempt 3...

Success retrieving token.
{"sessionid": "1cfd9ec91e6cc420691e2d0580462f25"}
```

### New cluster
If you want to deploy nodes to a 2nd cluster, first create a new cluster in the LCM console by clicking on the *Clusters* tab and then the plus sign above the column of clusters. Choose a new cluster name (eg `devCluster`) and the default credentials, config profile, and repo. Change the value of `clusterName` in the parameters file, and rerun the same command changing the deployment name (here `nodes3`) and choosing a new and **unique** value for the `namespace` parameter, eg here we pass in `devdc0` since `dc0` has been used previously. Using a non-unique value will result in namespace collisions when trying to create VM's. Note that https and auth for Opscenter must **not** be enabled to do this.

```
az group deployment create -f template-nodes.json -e parameters-nodes3.json mock nodes3
```
