#!/usr/bin/env bash

wget https://github.com/DSPN/install-datastax/archive/master.zip
apt-get -y install unzip
unzip install-datastax-master.zip
cd install-datastax-master/bin

./opscenter.sh
