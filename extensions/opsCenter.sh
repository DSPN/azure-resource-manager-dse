#!/usr/bin/env bash

wget https://github.com/DSPN/install-datastax/archive/master.zip
apt-get -y install unzip
unzip master.zip
cd master/bin

./opscenter.sh
