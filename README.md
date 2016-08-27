# azure-resource-manager-dse

These are Azure Resource Manager (ARM) templates for deploying DataStax Enterprise (DSE).  The [DataStax Deployment Guide for Azure](https://github.com/DSPN/azure-deployment-guide) is a good place to start.

Directory | Description
--- | ---
[extensions](./extensions) | Common scripts that are used by all the templates.  In ARM terminology these are referred to as Linux extensions.
[marketplace](./marketplace) | Used by the DataStax Azure Marketplace offer.  This is not intended for deployment outside of the Azure Marketplace.
[multidc](./multidc) | Python to generate an ARM template across multiple data centers and then deploy that.
[singledc](./singledc) | Bare bones template that deploys 1-40 nodes in a single datacenter.
