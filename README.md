# azure-resource-manager-dse

These are Azure Resource Manager (ARM) templates for deploying DataStax Enterprise (DSE).  The [DataStax Enterprise Deployment Guide for Microsoft Azure](https://academy.datastax.com/demos/enterprise-deployment-microsoft-azure-cloud) is a good place to start learning about these templates.

Directory | Description
--- | ---
[singledc](./singledc) | Bare bones template that deploys 1-40 nodes in a single datacenter.
[multidc](./multidc) | Python to generate an ARM template across multiple data centers and then deploy that.
[marketplace](./marketplace) | Used by the DataStax Azure Marketplace offer.  This template is very similar to singledc, but includes a few things required by the Azure Marketplace.  It is not intended for deployment outside of the Azure Marketplace.
[extensions](./extensions) | Common scripts that are used by all the templates.  In ARM terminology these are referred to as Linux extensions.
