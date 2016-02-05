This template deploys a DataStax Enterprise (DSE) cluster to Azure running on Ubuntu virtual machines. The template also provisions a storage account, virtual network and public IP address required by the installation.  The template will deploy to the location that the resourceGroup it is part of is located in.

The button below will deploy this template to Azure.  The template will be dynamically linked directly from this github repository.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FDSPN%2Fazure-resource-manager-dse%2Fmaster%2Fsimple%2FmainTemplate.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

The template expects the following parameters:

| Name   | Description |
|:--- |:---|
| clusterNodeCount | The number of virtual machines to provision for the cluster |
| clusterVmSize | The size of virtual machine to provision for each cluster node |
| adminUsername  | SSH username for the virtual machines |
| adminPassword  | SSH password for the virtual machines |

Once the Azure VMs, virtual network and storage are setup, the template installs prerequisites like Java on the DSE nodes.  These have static IPs starting at 10.0.0.6 which are accessible on the internal virtual network.  

The template also sets up a node to run DataStax OpsCenter.  This node has the internal IP 10.0.0.5 as well as an external IP.  Ports 22 (SSH), 8888 (HTTP), and 8443 (HTTPS) are enabled.

The script opscenter.sh installs OpsCenter and creates a cluster using the OpsCenter REST API.  When the API call is made, OpsCenter installs DSE on all the cluster nodes and starts it up.  

On completion, OpsCenter will be accessible at `http://{resourceGroup}cluster.{location}.cloudapp.azure.com:8888` For instance, if you created a deployment with the resourceGroup parameter set to datastax in the West US location you could access OpsCenter for the deployment at `http://datastaxcluster.westus.cloudapp.azure.com:8888`
