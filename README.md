# Deploy a DataStax Enterprise Cluster to Azure

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fazure-quickstart-templates%2Fmaster%2Fdatastax-enterprise%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

This template deploys a DataStax Enterprise cluster to Azure running on Ubuntu virtual machines. The template also provisions a storage account, virtual network, availability sets, public IP addresses and network interfaces required by the installation.

The template expects the following parameters:

| Name   | Description |
|:--- |:---|
| clusterName | The name of the new cluster |
| region | Region where the Azure artifacts will be created |
| clusterNodeCount | The number of virtual machines to provision for the cluster |
| clusterVmSize | The size of virtual machine to provision for each cluster node |
| adminUsername  | Admin user name for the virtual machines.  The OpsCenter user is admin. |
| adminPassword  | Admin password for the virtual machines and OpsCenter |
| datastaxUsername | Your DataStax account username.  You can register at (datastax.com) |
| datastaxPassword | Your DataStax account password |

A configurable number of cluster nodes of a configurable size are created.  These are prepared with prerequisites for OpsCenter. The cluster nodes IPs are statically assigned and only accessible on the internal virtual network.  After the cluster nodes are created, a single OpsCenter instance is provisioned.  It is responsible for provisioning and managing the cluster nodes.

This template will deploy the OpsCenter admin UI to `{clusterName}.{region}.cloudapp.azure.com:8888`. For instance, if you created a deployment with the clusterName parameter set to datastax in the West US region you could access the DataStax OpsCenter virtual machine for the deployment at `http://datastax.westus.cloudapp.azure.com:8888`.

The OpsCenter instance has port 22 for SSH, port 8888 for HTTP and port 8443 for HTTPS enabled.  

##Known Issues and Limitations
- We would prefer to derive the cluster name from the resource group as this would eliminate one more parameter.
- The certificate used in the deployment is a self signed certificate that will create a browser warning.  You can follow the process on the DataStax web site for replacing the certificate with your own SSL certificate.
- The template uses username/password for provisioning cluster nodes in the cluster. Ideally it would use an SSH key.
- The template deploys Cassandra data nodes configured to use ephemeral storage and attaches a data disk that can be used for data backups in the event of a cluster failure resulting in the loss of the data on the ephemeral disks.  Ideally it would use premium storage and support a backup strategy.
- Errors in OpsCenter provisioning are not currently passed up to the Azure log.

