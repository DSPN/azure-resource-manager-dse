#!/bin/bash

# be strict with errors
set -e

params="mainTemplateParameters.json"
# pull location/region from params since
# this is in the params created in the portal
location=$(jq .location.value $params | tr -d '"')
rand=$(LC_ALL=C tr -cd '[:alnum:]' < /dev/urandom | tr -cd '[:lower:]' | fold -w10 | head -n1)
rg="public-devonly-"$rand
storage="store"$rand

echo "Creating resource group $rg"
az group create --name $rg --location $location

echo "Creating tmp storage account $storage"
az storage account create --location $location --resource-group $rg --name $storage --sku Standard_LRS

echo "Creating container 'dstest' for templates/extensions"
az storage container create --name dstest --public-access "blob" --account-name $storage
az storage blob upload-batch --account-name $storage --destination dstest --source ./extensions
az storage blob upload-batch --account-name $storage --destination dstest --source ./templates

# baseUri has no default in the template
az group deployment create \
 --resource-group $rg \
 --template-file mainTemplate.json \
 --parameters @$params \
 --parameters '{"baseUrl": {"value": "https://'$storage'.blob.core.windows.net/dstest"}}' \
 --parameters '{"location": {"value": "'$location'"}}' \
 --verbose
