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
| datastaxUsername | Your DataStax account username.  You can register at http://www.datastax.com/download |
| datastaxPassword | Your DataStax account password |

A configurable number of cluster nodes of a configurable size are created.  These are prepared with prerequisites for OpsCenter. The cluster nodes IPs are statically assigned and only accessible on the internal virtual network.  After the cluster nodes are created, a single OpsCenter instance is provisioned.  It is responsible for provisioning and managing the cluster nodes.

This template will deploy OpsCenter to `http://{clusterName}.{region}.cloudapp.azure.com:8888` For instance, if you created a deployment with the clusterName parameter set to datastax in the West US region you could access OpsCenter for the deployment at `http://datastax.westus.cloudapp.azure.com:8888`

The OpsCenter virtual machine has port 22 for SSH, port 8888 for HTTP and port 8443 for HTTPS enabled.  

##Known Issues and Limitations (P0)
- We would prefer to derive the cluster name from the resource group as this would eliminate one more parameter.
- There's an intermittent issue where provisioning of the datadisk fails.
- There are intermittent issues with OpsCenter provisioning nodes.
- Currently logging in the shell scripts is directed to STDOUT.  We would prefer it be directed to the Azure audit log.
- Errors in OpsCenter provisioning are not currently passed up to the Azure log.
- Azure cli will return completed even while OpsCenter is still provisioning nodes.

##Known Issues and Limitations (P1)
- Deletion of a storage account takes some time (one estimate is 12 minutes) after the command is entered.  Given that, it is currently neccessary to give new clusters a different name than previously created clusters to avoid a name collision.
- There are various validations (is there a name conflict, is a password of sufficient strength, is a username valid) that are performed on the backend but not in the web UI.  Ideally this would happen in the web UI.
- Storage groups are limited to 40 nodes.  Currently our cluster shares a single storage group and is, as a result, limited to 40 nodes.
- Cannot provision more than 251 cluster nodes as the nodes are named 10.0.0.5, 10.0.0.6, ...
- The certificate used in the deployment is a self signed certificate that will create a browser warning.  You can follow the process for replacing the certificate with your own SSL certificate here: http://docs.datastax.com/en/opscenter/5.1/opsc/configure/opscConfiguringEnablingHttps_t.html
- The template uses username/password for provisioning cluster nodes in the cluster. Ideally it would offer an option to use an SSH key.
- We would like to offer a choice between premium and standard storage.  Currently only standard is supported.
- The template deploys DSE nodes configured to use ephemeral storage and attaches a data disk that can be used for data backups in the event of a cluster failure resulting in the loss of the data on the ephemeral disks.  Ideally we would automate this backup process.
- There is a for loop in opscenter.sh which does not scale well with large numbers of nodes.
- Would like to add support for selecting JVM and DSE versions from the template parameters.
- The parameters passed to OpsCenter need to be updated from DSE 4.6.3 to DSE 4.7.0
- Would like to parameterize whether the nodes are configured for default, spark or solr

