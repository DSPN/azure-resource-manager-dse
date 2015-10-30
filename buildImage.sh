#!/bin/sh

## The rest of the commands assume you are root, otherwise just prepend them with ‘sudo’
sudo -s
 
# Download and unzip the Ubuntu image
wget http://cloud-images.ubuntu.com/releases/14.04.3/release/ubuntu-14.04-server-cloudimg-amd64-disk1.vhd.zip
apt-get install unzip
unzip ubuntu-14.04-server-cloudimg-amd64-disk1.vhd.zip
 
# Convert the VHD to raw
apt-get install qemu-utils
qemu-img convert -f vpc -O raw trusty-server-cloudimg-amd64-disk1.vhd trusty-server-cloudimg-amd64-disk1.raw
 
# Mount the first partition in the raw disk
apt-get install kpartx
kpartx -a ./trusty-server-cloudimg-amd64-disk1.raw
mkdir /mnt2
mount /dev/mapper/loop0p1 /mnt2
 
# chroot, but first fixup resolv.conf so we can resolv hostnames in the chroot environment
mv /mnt2/etc/resolv.conf /mnt2/etc/resolv.conf.bak
cp /etc/resolv.conf /mnt2/etc/resolv.conf
chroot /mnt2
 
# Install Azul Zulu JDK
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0x219BD9C9
apt-add-repository -y "deb http://repos.azulsystems.com/ubuntu stable main"
apt-get -y update
apt-get -y install zulu-8
 
# Exit the chroot and unmount
rm /etc/resolv.conf
mv /etc/resolv.conf.bak /etc/resolv.conf
exit
umount /mnt2
 
# Convert the raw image back to VHD
rm trusty-server-cloudimg-amd64-disk1.vhd
qemu-img convert -f raw -O vpc -o subformat=fixed trusty-server-cloudimg-amd64-disk1.raw trusty-server-cloudimg-amd64-disk1.vhd

