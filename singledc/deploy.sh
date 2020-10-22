#!/bin/bash

# be strict with errors
set -e

params="./mainTemplateParametersUI.json"
#params="params/sidecar.json"
# pull location/region from params since
# this is in the params created in the portal
location=$(jq .location.value $params | tr -d '"')
rand=$(LC_ALL=C tr -cd '[:alnum:]' < /dev/urandom | tr -cd '[:lower:]' | fold -w10 | head -n1)
rg="enterprise-67-"$rand
storage="store"$rand

echo "Creating resource group $rg"
az group create --name $rg --location $location --tags lifecycle=0

echo "Creating tmp storage account $storage"
az storage account create --location $location --resource-group $rg --name $storage --sku Standard_LRS --tags lifecycle=0

echo "Creating container 'testdse' for templates/extensions"
az storage container create --name testdse --public-access "blob" --account-name $storage
az storage blob upload-batch --account-name $storage --destination testdse --source ./extensions
az storage blob upload-batch --account-name $storage --destination testdse --source ./templates

# baseUri has no default in the template
az deployment group create \
    --name $rg \
    --resource-group $rg \
    --template-file mainTemplate.json \
    --parameters @$params \
    --parameters '{"_artifactsLocation": {"value": "https://'$storage'.blob.core.windows.net/testdse/"}}' \
    --parameters '{"location": {"value": "'$location'"}}' \
    --verbose
