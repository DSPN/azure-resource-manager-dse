#!/bin/bash

password=$1
trys=20
sleep='10s'

cp /etc/opscenter/opscenterd.conf /etc/opscenter/opscenterd.conf.bak
echo "Turn on OpsC auth"
sed -ie 's/enabled = False/enabled = True/g' /etc/opscenter/opscenterd.conf

echo "Turn on SSL"
sed -ie 's/#ssl_keyfile/ssl_keyfile/g' /etc/opscenter/opscenterd.conf
sed -ie 's/#ssl_certfile/ssl_certfile/g' /etc/opscenter/opscenterd.conf
sed -ie 's/#ssl_port/ssl_port/g' /etc/opscenter/opscenterd.conf

echo "Start OpsC"
service opscenterd restart

if [ -z $password ]; then
  echo "No pw arg, leaving default pw, exiting"
  exit 0
fi

echo "Connect to OpsC after start..."

for i in `seq 1 $trys`;
do
  echo "Attempt $i..."
  json=$(curl --retry 10 -k -s -X POST -d '{"username":"admin","password":"admin"}' 'https://localhost:8443/login')
  RET=$?

  if [[ $json == *"sessionid"* ]]; then
    echo "sessionid retrieved"
    break
  fi

  if [ $RET -eq 0 ]
  then
    echo -e "\nUnexpected response: $json"
    continue
  fi

  if [ $i -eq $trys ]
  then
    echo "Failure after 10 trys, revert to original config, restart opscenterd, and exit"
    cp /etc/opscenter/opscenterd.conf.bak /etc/opscenter/opscenterd.conf
    service opscenterd restart
    exit 1
  fi

  sleep $sleep
done

token=$(echo $json | tr -d '{} ' | awk -F':' {'print $2'} | tr -d '"')
curl -s -k -H 'opscenter-session: '$token -H 'Accept: application/json' -d '{"password": "'$password'", "old_password": "admin" }' -X PUT https://localhost:8443/users/admin
