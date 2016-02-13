#!/usr/bin/env bash

wget https://github.com/DSPN/install-datastax/archive/master.zip
unzip install-datastax-master.zip
cd install-datastax-master/bin
./dse.sh
