main is a set of Python scripts that generate an ARM template.  This supports multiple data centers and is highly customizable.

A script called deploy.sh is the main entry point.  This takes the name of a resource group as a parameter.  deploy.sh creates that resource group, generates an ARM template by invoking main.py and submits that template to Azure.  The template created is written to ./generatedTemplate.json

main.py reads from the following parameters from ./clusterParameter.json:

| Name   | Description |
|:--- |:---|
| regions | A list of regions to deploy DSE datacenters to |
| nodesPerRegion | The number of DSE nodes to deploy in each datacenter |
| nodeSize | The size of virtual machine to provision for each cluster node |
| username  | SSH username for the virtual machines |
| password  | SSH password for the virtual machines |

Once the Azure VMs, virtual networks, gateways, storage, etc are setup, the template installs prerequisites like Java on the DSE nodes.  These have static IPs starting at 10.x.1.5 which are accessible on the internal virtual network where x is 1 for the first region in the parameters passed in, 2 for the second and so on.  VPN gateways are configured to route traffic between regions.

The template also sets up a node to run DataStax OpsCenter.  This node has the internal IP 10.0.1.5 as well as an external IP.  Ports 22 (SSH), 8888 (HTTP), and 8443 (HTTPS) are enabled.  This external IP is your access point to the cluster from the internet.

The script opsCenter.sh installs OpsCenter and creates a cluster using the OpsCenter REST API.  When the API call is made, OpsCenter installs DSE on all the cluster nodes and starts it up.  

On completion, OpsCenter will be accessible at `http://{resourceGroup}cluster.{region}.cloudapp.azure.com:8888` For instance, if you created a deployment with in a resourceGroup named datastax and located in the West US region, you could access OpsCenter for the deployment at `http://datastaxcluster.westus.cloudapp.azure.com:8888`

By default, OpsCenter authentication and SSL are disabled.  You can enable them by running extensions/turnOnOpsCenterAuth.sh
