multi-datacenter is a set of Python scripts that generate an ARM template.  This supports multiple data centers and is highly customizable.

A script called deploy.sh is the main entry point.  This takes the name of a resource group as a parameter.  deploy.sh creates that resource group, generates an ARM template by invoking main.py and submits that template to Azure.  The template created is written to ./generatedTemplate.json

main.py reads from the following parameters from ./clusterParameter.json:

| Name   | Description |
|:--- |:---|
| locations | A list of locations to deploy DSE datacenters to |
| nodeCount | The number of DSE nodes to deploy in each datacenter |
| vmSize | The size of virtual machine to provision for each cluster node |
| adminUsername  | Admin user name for the virtual machines |
| adminPassword  | Admin password for the virtual machines |

Once the Azure VMs, virtual networks, gateways, storage, etc are setup, the template installs prerequisites like Java on the DSE nodes.  These have static IPs starting at 10.x.1.5 which are accessible on the internal virtual network where x is 1 for the first location in the parameters passed in, 2 for the second and so on.  VPN gateways are configured to route traffic between locations.

The template also sets up a node to run DataStax OpsCenter.

The script opsCenter.sh installs OpsCenter and creates a cluster using the OpsCenter REST API.  When the API call is made, OpsCenter installs DSE on all the cluster nodes and starts it up.