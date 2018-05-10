
resource_group='jcp-nettest'
location='westus2'
vnet='testvnet'
subnet='testsubnet'
vm='testvm'
user='datastax'
pw='foofoo123123!'

rand=$(LC_ALL=C tr -cd '[:alnum:]' < /dev/urandom | tr -cd '[:lower:]' | fold -w10 | head -n1)

az group create --name $resource_group --location $location
az network vnet create -g $resource_group -n $vnet --subnet-name $subnet

az vm create -n $vm -g $resource_group \
  --public-ip-address-dns-name $vm$rand \
  --image ubuntults \
  --size Standard_DS2_v2 \
  --vnet-name $vnet --subnet $subnet \
  --authentication-type password --admin-password $pw --admin-username $user


