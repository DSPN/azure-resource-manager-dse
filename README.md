# azure-resource-manager-dse

These scripts are under development and have some issues.

These are Azure Resource Manager (ARM) templates for deploying DataStax Enterprise (DSE).  The [DataStax Enterprise Deployment Guide for Microsoft Azure](https://academy.datastax.com/demos/enterprise-deployment-microsoft-azure-cloud) is a good place to start learning about these templates.

Directory | Description
--- | ---
[singledc](./singledc) | Bare bones template that deploys 1-40 nodes in a single datacenter.
[multidc](./multidc) | Python to generate an ARM template across multiple data centers and then deploy that.
[extensions](./extensions) | Common scripts that are used by all the templates.  In ARM terminology these are referred to as Linux extensions.
