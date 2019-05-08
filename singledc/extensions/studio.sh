#!/usr/bin/env bash

user=$1

echo "Installing DS Studio..."

cd /home/$user
sversion='6.0.2'
curl -sS -O https://dsetestdrivestor.blob.core.windows.net/studio/datastax-studio-$sversion.tar.gz
tar -xf datastax-studio-$sversion.tar.gz
# open up connections
sed -i -e 's/httpBindAddress: localhost/httpBindAddress: 0.0.0.0/g' ./datastax-studio-$sversion/conf/configuration.yaml
# DONT setup connection
echo "Remove sparksql example..."
rm ./datastax-studio-$sversion/examples/notebooks/3a0a2fc4-d7d7-40ba-9438-8d672da3c1d5
echo "Add instruction notebook..."
curl -sS -O https://dsetestdrivestor.blob.core.windows.net/studio/32714686-1bbd-45cd-bed4-c95de5c242d0
mv 32714686-1bbd-45cd-bed4-c95de5c242d0 ./datastax-studio-$sversion/examples/notebooks/
# make not root owned
chown -R $user:$user ./datastax-studio-$sversion

# actually start
echo "Starting studio with nohup... $(date)"
sudo -u $user nohup ./datastax-studio-$sversion/bin/server.sh > ~datastax/studio.log &
