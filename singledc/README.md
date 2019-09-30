These templates and associated scripts are for develpment purposes only. They may not run in all client environments and are meant to be a starting point for Datastax Enterprise deployments on Azure and not for production environments.

This template deploys a DataStax Enterprise (DSE) cluster to Azure running on Ubuntu virtual machines in a single datacenter.  The template will provision a 3 node cluster.  

The template also provisions managed disks, virtual network and public IP addresses required by the installation.  The template will deploy to the location that the resourceGroup it is part of is located in. The template also sets up a vm to run DataStax OpsCenter.  The script opscenter.sh installs OpsCenter and performs basic cluster setup.

Alternatively, you can run clone this repo and run `deploy.sh`. This script will randomly generate a resource group and deploy into the region specified in the mainTemplateParameters.json file

```
./deploy.sh
---------------------------------------------------
Usage:
deploy.sh


---------------------------------------------------
```

The template expects the following parameters (examples of which are in `mainTemplateParameters.json`):

| Name   | Description |
|:--- |:---|
| nodeCount | Number of virtual machines to provision for the cluster |
| vmSize | Size of virtual machine to provision for the cluster |
| adminUsername  | Admin user name for the virtual machines |
| adminPassword  | Admin password for the virtual machines |
| DBPassword  | Password for default C* user 'cassandra' |
| OpsCPassword | Password for default OpsCenter user 'admin' |

The template also takes the following optional parameters (examples *not* included in `mainTemplateParameters.json`):

| Name   | Description |
|:--- |:---|
| DSEVersion | Default '6.7.3', allowed values '6.7.3' / '5.1.15' |
| clusterName | Default 'DSECluster', name of cluster in OpsCenter |
| datacenterName | Default 'dc0', name of DSE datacenter and namespace prefix for node VMs and related resources |
| opscvmSize | Default 'Standard_D2s_v3' |
| publicIpOnNodes | Default 'yes', setting to 'no' will create no public IPs on node VMs |


On completion, OpsCenter will be accessible on port 8443 (https, http connections to port 8888 will be redirected) of the public IP address of the OpsCenter node. OpsCenter uses a self-signed SSL certificate, so you will need to accept the certificate exception. After this you can log in with the user name 'admin' and the password you specified in the OpsCPassword parameter.
