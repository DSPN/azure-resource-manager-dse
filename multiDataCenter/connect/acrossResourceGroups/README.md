The steps to deploy a two region DSE instance manually are given in deploy.sh.

If you are using the portal, you can use the deploy buttons below:

First create two resource groups.  These two steps can happen in parallel.

Then deploy nodes using the simple and simpleAlternateSubnet templates.  These two steps can happen in parallel.

Deploy nodes in 10.0.x.y:
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FDSPN%2Fazure-arm-dse%2Fmaster%2Fsimple%2FmainTemplate.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

Deploy nodes in 10.1.x.y:
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FDSPN%2Fazure-arm-dse%2Fmaster%2FmultiDataCenter/simpleAlternateSubnet%2FmainTemplate.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

After that, you'll want to deploy gateways into each of the clusters.  Note, these two steps can happen in parallel:

Gateway 1:
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FDSPN%2Fazure-arm-dse%2Fmaster%2FmultiDataCenter/connect%2FacrossResourceGroups/gateway1.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

Gateway 2:
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FDSPN%2Fazure-arm-dse%2Fmaster%2FmultiDataCenter/connect%2FacrossResourceGroups/gateway2.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

Finally, connect the two gateways:
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FDSPN%2Fazure-arm-dse%2Fmaster%2FmultiDataCenter/connect%2FacrossResourceGroups/connect.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

After that is complete, you will need to manually configure DataStax Enterprise to use two data centers.

Note, this is an extremely manual process.  We are currently working to automate it.

