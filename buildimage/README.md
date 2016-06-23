# Build Image

azure group create DSE-Image-RG SouthCentralUS
azure vm quick-create DSE-Image-RG SouthCenteralUS Linux Canonical:UbuntuServer

ARM
 
azure group create DSE-Image-RG SouthCentralUS
 
azure vm quick-create --vm-size Standard_DS14_v2 DSE-Image-RG dse-image SouthCentralUS Linux Canonical:UbuntuServer:14.04.4-LTS:latest image-160622
 
ssh image-160622@104.214.108.221
 
As root:
 
apt-get -y install software-properties-common
add-apt-repository -y ppa:webupd8team/java
apt-get -y update
 
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
 
echo "deb http://datastax%40microsoft.com:3A7vadPHbNT@debian.datastax.com/enterprise stable main" | sudo tee -a /etc/apt/sources.list.d/datastax.sources.list
 
curl -L http://debian.datastax.com/debian/repo_key | sudo apt-key add -
 
dse_version=4.8.5-1
apt-get -y update
 
apt-get -y download dse-full=$dse_version dse=$dse_version dse-hive=$dse_version dse-pig=$dse_version dse-demos=$dse_version dse-libsolr=$dse_version dse-libtomcat=$dse_version dse-libsqoop=$dse_version dse-liblog4j=$dse_version dse-libmahout=$dse_version dse-libhadoop-native=$dse_version dse-libcassandra=$dse_version dse-libhive=$dse_version dse-libpig=$dse_version dse-libhadoop=$dse_version dse-libspark=$dse_version
 
 
Out of VM:
 
azure vm stop DSE-Image-RG dse-image
azure vm generalize DSE-Image-RG dse-image
 
SAS URL
 
azure storage account connectionstring show cli23088123813475934758
 
azure storage blob sas create vhds clie878418583e01667-os-1466625355650.vhd r 06/30/2016 -c "DefaultEndpointsProtocol=https;AccountName=cli23088123813475934758;AccountKey=WBXTCcfvsVynCLfLRL8cSL74tvz9MzJd4JOKVsbSQbVULQuY9Kb96nJFHSapAQlDFmH6g9MGxtBh/wxWrWvZQQ=="