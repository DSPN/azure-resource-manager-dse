# azure-resource-manager-dse

These are Azure Resource Manager (ARM) templates for deploying DataStax Enterprise (DSE).

simple is likely your default template.  It's a bare bones ARM template than we're working to further pare down and make easy to understand and get started.

main uses Python to generate an ARM template.  This is highly customizable and supports multiple datacenters.  This is the suggested option for advanced users.

marketplace is used by the DataStax Azure Marketplace offer.  This is not intended for deployment outside of the Azure Marketplace.

multiDataCenter is a deprecated solution for multi DC.  This is extremely manual, poorly documented and will be dropped from this repo soon.

