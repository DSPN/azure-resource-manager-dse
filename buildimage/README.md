# Build Image

This README describes how we build the VM that the templates use.  As a user of these templates, you should not need to do this.

General documentation on this process is here:
https://azure.microsoft.com/en-us/documentation/articles/marketplace-publishing-vm-image-creation/
https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-linux-classic-create-upload-vhd/

## Create a VM
 
    azure group create DSE-Image-RG SouthCentralUS
    azure vm quick-create --vm-size Standard_DS14_v2 DSE-Image-RG dseimage SouthCentralUS Linux Canonical:UbuntuServer:14.04.4-LTS:latest image-160622

The quick-create command will prompt for a password.  That password is for the SSH credentials to the machine.

SSH into the image.  If the command above was used, the username will be image-160622.

## Install Java on the VM

    sudo su
    apt-get -y install software-properties-common
    add-apt-repository -y ppa:webupd8team/java
    apt-get -y update
    echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
    echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections

## Download (but don't install) DataStax Enterprise

    dse_version=5.0.1-1
    opscenter_version=6.0.1
    
    echo "deb http://datastax%40microsoft.com:3A7vadPHbNT@debian.datastax.com/enterprise stable main" | sudo tee -a /etc/apt/sources.list.d/datastax.sources.list
    curl -L http://debian.datastax.com/debian/repo_key | sudo apt-key add -
    
    apt-get -y update
    apt-get -y -d install dse-full=$dse_version dse=$dse_version dse-hive=$dse_version dse-pig=$dse_version dse-demos=$dse_version dse-libsolr=$dse_version dse-libtomcat=$dse_version dse-libsqoop=$dse_version dse-liblog4j=$dse_version dse-libmahout=$dse_version dse-libhadoop-native=$dse_version dse-libcassandra=$dse_version dse-libhive=$dse_version dse-libpig=$dse_version dse-libhadoop=$dse_version dse-libspark=$dse_version
    apt-get -y -d install opscenter=$opscenter_version datastax-agent=$opscenter_version

## Clear the history

You'll want to run this command twice.  The first time will clear root's history and exit.  The second will clear your user's history and exit.

    cat /dev/null > ~/.bash_history && history -c && exit
    cat /dev/null > ~/.bash_history && history -c && exit

be sure to stop and deallocate the vm

## From the local Azure CLI 
    azure vm stop DSE-Image-RG dseimage
    azure vm generalize DSE-Image-RG dseimage
 
## Get the SAS URL

Run this command to get a URL for the storage account.  You can lookup the name in the portal.  In my case it was clisto2811037585dseimage.

    azure storage account connectionstring show <name of your storage account>

    con="DefaultEndpointsProtocol=https;AccountName=cli15207440163475934758;AccountKey=<your key>"
    azure storage container list -c $con

Make sure the image is a VHD.

    azure storage blob list vhds -c $con

You'll be prompted for the resource group name.  Enter DSE-Image-RG.

    azure storage container sas create vhds rl 09/30/2016 -c $con --start 07/23/2016

This creates a URL for the img:

https://cli15207440163475934758.blob.core.windows.net/vhds?st=2016-07-23T07%3A00%3A00Z&se=2016-09-30T07%3A00%3A00Z&sp=rl&sv=2015-04-05&sr=c&sig=%2BEHZBhu%2FHkZeGTbL3jhKD%2Br1%2F72SvL3btNMHlgD5ERk%3D

to get the sas url, add cli etc after vhds as follows:

https://cli15207440163475934758.blob.core.windows.net/vhds/cli6368b7095406bb59-os-1469464726649.vhd?st=2016-07-23T07%3A00%3A00Z&se=2016-09-30T07%3A00%3A00Z&sp=rl&sv=2015-04-05&sr=c&sig=%2BEHZBhu%2FHkZeGTbL3jhKD%2Br1%2F72SvL3btNMHlgD5ERk%3D

make sure it works by wget -O tmp.vhd <sas url>
