# Deploy a DataStax Enterprise Cluster to Azure

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FDSPN%2Fazure-arm-dse%2Fmaster%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

This template deploys a DataStax Enterprise cluster to Azure running on Ubuntu virtual machines. The template also provisions a storage account, virtual network, public IP address and the network interfaces required by the installation.

The template expects the following parameters:

| Name   | Description |
|:--- |:---|
| clusterName | The name of the new cluster |
| region | Region where the Azure artifacts will be created |
| clusterNodeCount | The number of virtual machines to provision for the cluster |
| clusterVmSize | The size of virtual machine to provision for each cluster node |
| adminUsername  | Admin user name for the virtual machines |
| adminPassword  | Admin password for the virtual machines |
| datastaxUsername | Your DataStax account username.  You can register at http://www.datastax.com/download |
| datastaxPassword | Your DataStax account password.  You can register at http://www.datastax.com/download |

A configurable number of cluster nodes of a configurable size are created.  These are prepared with prerequisites for OpsCenter. The cluster nodes IPs are statically assigned and only accessible on the internal virtual network.  After the cluster nodes are created, a single OpsCenter instance is provisioned.  It is responsible for provisioning and managing the cluster nodes.

This template will deploy OpsCenter to `http://{clusterName}.{region}.cloudapp.azure.com:8888` For instance, if you created a deployment with the clusterName parameter set to datastax in the West US region you could access OpsCenter for the deployment at `http://datastax.westus.cloudapp.azure.com:8888`

The OpsCenter virtual machine has a public IP with ports 22 (SSH), 8888 (HTTP), and 8443 (HTTPS) enabled.

