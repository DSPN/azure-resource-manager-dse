#!/bin/bash

echo "Installing OpenJDK 7"
apt-get -y update
apt-get -y install openjdk-7-jdk

#echo "Installing Azul Zulu JDK"
#apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0x219BD9C9
#apt-add-repository -y "deb http://repos.azulsystems.com/ubuntu stable main"
#apt-get -y update
#apt-get -y install zulu-8

