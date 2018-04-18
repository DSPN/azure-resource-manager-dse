# To deploy:

* Run `deploy.sh -g rgname` where *rgname* is the desired resource group name.
* Deploy in the Azure portal by following this <a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FDSPN%2Fazure-resource-manager-dse%2Fworkshop%2Fsingledc%2FmainTemplate.json" target="_blank">portal link</a>

# Scripts:
The shell scripts in this directory are self documenting, run with `-h` to see arguments/options

## deploy.sh
```
---------------------------------------------------
Usage:
deploy.sh [-h] [-g resource-group] [-l location]

Options:

 -h                 : display this message and exit
 -g resource-group  : name of resource group to create, default 'dse'
 -l location        : location for resource group, default 'eastus'

---------------------------------------------------
```

## deploy_many.sh
```
---------------------------------------------------
Usage:
deploy.sh [-h] [-g resource-group] [-l location] [-n num]

Deploy -n workshop clusters to one region -l with name prefix -g
Deployment outputs will be appended to ./output.csv as each
deployment completes.

Options:

 -h                 : display this message and exit
 -g resource-group  : PREFIX for name of resource group to create, default 'dse'
                      Resource groups will be named prefix1 ... prefixN
                      Names must be UNIQUE AT THE ACCOUNT LEVEL
 -l location        : location for resource group, default 'westus2'
 -n num             : number of deployments, default 3

---------------------------------------------------

```

## teardown.sh
Complements `deploy_many.sh`, will prompt *once* before deleting.
```
---------------------------------------------------
Usage:
deploy.sh [-h] -g resource-group -n num

Delete resource groups prefix1 ... prefixN
Will prompt once before deleting.

Options:

 -h                 : display this message and exit
 -g resource-group  : PREFIX for name of resource groups to DELETE
                      Resource groups assumed to be named prefix1 ... prefixN
 -n num             : number of deployments

---------------------------------------------------
```
