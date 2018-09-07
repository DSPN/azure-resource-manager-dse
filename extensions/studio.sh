#!/usr/bin/env bash

user=$1

echo "Installing DS Studio..."

cd /home/$user
sversion='6.0.2'
curl -sS -O https://dsetestdrivestor.blob.core.windows.net/studio/datastax-studio-$sversion.tar.gz
tar -xf datastax-studio-$sversion.tar.gz
# DONT setup connection
echo "Remove sparksql example..."
rm ./datastax-studio-$sversion/examples/notebooks/3a0a2fc4-d7d7-40ba-9438-8d672da3c1d5
# make not root owned
chown -R $user:$user ./datastax-studio-$sversion

# actually start
echo "Starting studio with nohup... $(date)"
sudo -u $user nohup ./datastax-studio-$sversion/bin/server.sh > ~datastax/studio.log &
