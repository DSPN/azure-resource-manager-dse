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
| adminUsername  | Admin user name for the virtual machines.  The OpsCenter user is admin. |
| adminPassword  | Admin password for the virtual machines and OpsCenter |
| datastaxUsername | Your DataStax account username.  You can register at (datastax.com) |
| datastaxPassword | Your DataStax account password |

A configurable number of cluster nodes of a configurable size are created.  These are prepared with prerequisites for OpsCenter. The cluster nodes IPs are statically assigned and only accessible on the internal virtual network.  After the cluster nodes are created, a single OpsCenter instance is provisioned.  It is responsible for provisioning and managing the cluster nodes.

This template will deploy OpsCenter to `{clusterName}.{region}.cloudapp.azure.com:8443` For instance, if you created a deployment with the clusterName parameter set to datastax in the West US region you could access OpsCenter for the deployment at `http://datastax.westus.cloudapp.azure.com:8443`

The OpsCenter virtual machine has port 22 for SSH, port 8888 for HTTP and port 8443 for HTTPS enabled.  

##Known Issues and Limitations
- We would prefer to derive the cluster name from the resource group as this would eliminate one more parameter.
- The certificate used in the deployment is a self signed certificate that will create a browser warning.  You can follow the process on the DataStax web site for replacing the certificate with your own SSL certificate.
- The template uses username/password for provisioning cluster nodes in the cluster. Ideally it would offer an option to use an SSH key.
- The template deploys DSE nodes configured to use ephemeral storage and attaches a data disk that can be used for data backups in the event of a cluster failure resulting in the loss of the data on the ephemeral disks.  Ideally it would offer a choice better ephemeral and premium storage.  Additionally, it might support a backup strategy.
- Errors in OpsCenter provisioning are not currently passed up to the Azure log.
- Azure cli will return completed even while OpsCenter is still provisioning nodes.
- There are various validations (is there a name conflict, is a password of sufficient strength, is a username valid) that are performed on the backen but not in the web UI.  Ideally this would happen in the web UI.

