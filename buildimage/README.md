# Build Image

This README describes how we build the VM that the templates use.  As a user of these templates, you should not need to do this.

General documentation on this process is here:
* https://azure.microsoft.com/en-us/documentation/articles/marketplace-publishing-vm-image-creation/
* https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-linux-classic-create-upload-vhd/
* https://docs.microsoft.com/en-us/azure/virtual-machines/virtual-machines-linux-capture-image

## Identify the VM Image to Use

    azure vm image list-skus SouthCentralUS Canonical UbuntuServer

## Create a VM

    azure group create DSE-Image-RG SouthCentralUS
    azure vm quick-create --vm-size Standard_DS14_v2 DSE-Image-RG dseimage SouthCentralUS Linux Canonical:UbuntuServer:16.04.0-LTS:latest image-160622

The quick-create command will prompt for a password.  That password is for the SSH credentials to the machine.

SSH into the image.  If the command above was used, the username will be image-160622.

## Install Java on the VM

    sudo su
    apt-get -y install software-properties-common
    add-apt-repository -y ppa:webupd8team/java
    apt-get -y update
    echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
    echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections

## Add the DataStax repo

    echo "deb http://datastax%40microsoft.com:3A7vadPHbNT@debian.datastax.com/enterprise stable main" | sudo tee -a /etc/apt/sources.list.d/datastax.sources.list
    curl -L http://debian.datastax.com/debian/repo_key | sudo apt-key add -
    apt-get -y update

## Check what versions of DSE and OpsCenter are currently available.

    apt-cache showpkg opscenter
    apt-cache showpkg dse-full

## Download (but don't install) DataStax Enterprise

    dse_version=5.0.5-1
    opscenter_version=6.0.7
    apt-get -y -d install dse-full=$dse_version dse=$dse_version dse-hive=$dse_version dse-pig=$dse_version dse-demos=$dse_version dse-libsolr=$dse_version dse-libtomcat=$dse_version dse-libsqoop=$dse_version dse-liblog4j=$dse_version dse-libmahout=$dse_version dse-libhadoop-native=$dse_version dse-libcassandra=$dse_version dse-libhive=$dse_version dse-libpig=$dse_version dse-libhadoop=$dse_version dse-libspark=$dse_version
    apt-get -y -d install opscenter=$opscenter_version datastax-agent=$opscenter_version

## Clear the history

You'll want to run this command twice.  The first time will clear root's history and exit.  The second will clear your user's history and exit.

    cat /dev/null > ~/.bash_history && history -c && exit
    cat /dev/null > ~/.bash_history && history -c && exit

## Stop, Deallocate and Generalize the VM

    azure vm stop DSE-Image-RG dseimage
    azure vm deallocate DSE-Image-RG dseimage
    azure vm generalize DSE-Image-RG dseimage

## Get the SAS URL

Run this command to get a URL for the storage account.  You can lookup the name in the portal.  In my case it was stosnrc0v8cyb40.

    azure storage account connectionstring show <name of your storage account>
    con="DefaultEndpointsProtocol=https;AccountName=stosnrc0v8cyb40;AccountKey=<your key>"
    azure storage container list -c $con

Make sure the image is a vhd.

    azure storage blob list vhds -c $con

Now we need to create a URL for the image.  

The Publish Portal could potentially print an error: "The SAS URL start date (st) for the SAS URL should be one day before the current date in UTC, please ensure that the start date for SAS link is on or before 1/23/2017. Please ensure that the SAS URL is generated following the instructions available in the [help link](https://docs.microsoft.com/en-us/azure/marketplace-publishing/marketplace-publishing-vm-image-creation)."

    azure storage container sas create vhds rl 02/24/2017 -c $con --start 01/23/2017

The "Shared Access URL" should look something like this:

    https://stosnrc0v8cyb40.blob.core.windows.net/vhds?st=2017-01-23T08%3A00%3A00Z&se=2017-02-24T08%3A00%3A00Z&sp=rl&sv=2015-04-05&sr=c&sig=woWQmN9YIm3jkWq8ZRzieUlX5SCigNDfOENzq7PzS7Y%3D

to get the sas url, add cli etc after vhds as follows:

    https://stosnrc0v8cyb40.blob.core.windows.net/vhds/cli4ba15cd2b2977623-os-1485296531848.vhd?st=2017-01-23T08%3A00%3A00Z&se=2017-02-24T08%3A00%3A00Z&sp=rl&sv=2015-04-05&sr=c&sig=woWQmN9YIm3jkWq8ZRzieUlX5SCigNDfOENzq7PzS7Y%3D

Make sure it works by running:

    url="https://stosnrc0v8cyb40.blob.core.windows.net/vhds/cli4ba15cd2b2977623-os-1485296531848.vhd?st=2017-01-23T08%3A00%3A00Z&se=2017-02-24T08%3A00%3A00Z&sp=rl&sv=2015-04-05&sr=c&sig=woWQmN9YIm3jkWq8ZRzieUlX5SCigNDfOENzq7PzS7Y%3D"
    wget -O tmp.vhd $url

Once you can successfully get the image, proceed to the publisher portal.
