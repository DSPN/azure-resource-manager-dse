This template deploys a DataStax Enterprise (DSE) cluster to Azure running on Ubuntu virtual machines in a single datacenter.  The template can provision a cluster from 1 to 40 nodes.  Creating a greater number of nodes may cause issues with storage account I/O contention.

The template also provisions a storage account, virtual network and public IP addresses required by the installation.  The template will deploy to the location that the resourceGroup it is part of is located in.

The button below will deploy this template to Azure.  The template will be dynamically linked directly from this github repository.  Given that, if you want to make changes to subtemplates or extensions, be sure to fork the repo and adjust the baseUrl.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FDSPN%2Fazure-resource-manager-dse%2Fmaster%2Fsingledc%2FmainTemplate.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

The template expects the following parameters:

| Name   | Description |
|:--- |:---|
| nodeCount | Number of virtual machines to provision for the cluster |
| vmSize | Size of virtual machine to provision for the cluster |
| adminUsername  | Admin user name for the virtual machines |
| adminPassword  | Admin password for the virtual machines |

Once the Azure VMs, virtual network and storage are setup, the template installs Java and DSE on the nodes.  It also configures them.  These nodes are assigned both private and public dynamic IP addresses.

The template also sets up a node to run DataStax OpsCenter.  The script opscenter.sh installs OpsCenter and connects to the cluster by calling the OpsCenter REST API.

On completion, OpsCenter will be accessible on port 8888 of the public IP address of the OpsCenter node.

# How To

This document describes how to use templates to deploy DataStax Enterprise (DSE) on Microsoft Azure.

2 Deploy

Deploying to Azure will require an Azure account.  New users can sign up for a free trial that includes a $200 credit.  Note that the quotas on a free trial are significantly lower than those of an Azure Enterprise Agreement (EA) or even a normal credit card based account.

2.1 Deploy Using the Azure Marketplace

DataStax has an Azure Marketplace offer.  This is a bring your own license (BYOL) offer that supports deployment of a single datacenter. The youtube video below gives a detailed walkthrough showing how to deploy a DataStax Enterprise cluster using the Azure Marketplace offers.  The Azure Marketplace offer is available here.



2.2 Deploy Using the Azure CLI

Command line deployments can be accomplished using the Azure CLI or Azure PowerShell.  We typically recommend the CLI as it is cross platform and can be used on Windows, Linux and the Mac.  Detailed instructions on installing the Azure CLI are available at https://azure.microsoft.com/en-us/documentation/articles/xplat-cli-install/

DataStax has built a GitHub repo that has a number of Azure Resource Manager (ARM) templates, including a template that uses VPN Gateways to create a multi datacenter deployment. Those are available here.

The youtube video below gives a detailed walkthrough showing how to deploy a DataStax Enterprise cluster using the Azure CLI.



2.3 Debugging Deployments

In the event a deployment doesn't complete successfully, there are a number of steps you can take to understand the problem.  This video describes where various logs can be found.



2.4 Next Steps

Once you've deployed a cluster on Azure, there are a number of places you can go.  This video covers what to do next.  If you're not yet familiar with DataStax Enterprise and Cassandra, the courses at https://academy.datastax.com/ may be helpful.
