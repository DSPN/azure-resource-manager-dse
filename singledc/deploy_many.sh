#!/bin/bash

resource_group='dse'
location='westus2'
num=3
usage="
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

---------------------------------------------------"

# parse options
while getopts 'hg:l:n:' opt; do
  case $opt in
    h) echo -e "$usage"
       exit 1
    ;;
    g) resource_group="$OPTARG"
    ;;
    l) location="$OPTARG"
    ;;
    n) num="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
        exit 1
    ;;
  esac
done

# print awesome warning
echo "WARNING"
echo "WARNING: baseUrl hard coded to 'workshop'"
echo "WARNING"

# check 'az' is in path, else exit
if [ -z "$(which az)" ]; then
    echo "CLI v2 'az' command not found. Please install: https://docs.microsoft.com/en-us/cli/azure/install-az-cli2"
    exit 1
fi
if [ -z "$(which jq)" ]; then
    echo "'jq' command not found. Please install: https://stedolan.github.io/jq/"
    exit 1
fi
echo "CLI v2 'az' command found, 'jq' command found"
echo "Using values: resource_group=$resource_group location=$location num=$num"

# loop over 1...$num, creating resouce group prefix$i
# deploy into RG and backgrounds
list=()
for i in `seq 1 $num`;
do
  name="$resource_group$i"
  echo "Creating resource group: $name"
  az group create --name $name --location $location
  echo -e "Deploying into resource group: $name\n"
  az group deployment create \
   --resource-group $name \
   --template-file mainTemplate.json \
   --parameters @mainTemplateParameters.json &
   # append $name to list so we can get deployment outputs later
   list+=($name)
done
# block for deployments to complete
# this will block untill ALL calls have returned
echo "Waiting for backgrounded deployments..."

# loop over deployments and append outputs to csv
# as soon as sucess is reached
echo '"ResourceGroup", "opsCenterURL", "lifecycleManagerURL", "studioURL", "docsURL", "username", "userPassword"' >> output.csv
count=0
while [  $count -lt $num ]; do
  echo "$count/$num deployments finished."
  echo "Checking deployments..."

  for i in ${!list[@]}; do
    name=${list[$i]}
    echo "Getting output of deployment: $name"
    # store whole output
    output=$(az group deployment show -n mainTemplate -g $name)
    # parse individual values with jq
    status=$(echo $output | jq .properties.provisioningState)
    opsc=$(echo $output | jq .properties.outputs.opsCenterURL.value)
    lcm=$(echo $output | jq .properties.outputs.lifecycleManagerURL.value)
    studio=$(echo $output | jq .properties.outputs.studioURL.value)
    docs=$(echo $output | jq .properties.outputs.docsURL.value)
    user=$(echo $output | jq .properties.outputs.username.value)
    pw=$(echo $output | jq .properties.outputs.userPassword.value)
    if [ "$status" = "\"Succeeded\"" ]; then
     echo "Deployment $name succeeded, writing outputs"
     echo "$name, $opsc, $lcm, $studio, $docs, $user, $pw" >> output.csv
     # remove successful name and increment counter
     unset 'list[i]'
     ((count++))
    fi
  done

  echo "Sleeping 60s..."
  sleep 60s
done


echo "Deployments finished"

# things that don't work...
# shopt -s huponexit
# kill subshells if needed
# trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT
