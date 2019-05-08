#!/usr/bin/env bash

usage="---------------------------------------------------
Usage:
install_java.sh [-h] [-m]

Options:

 -h   : display this message and exit
 -m   : manual tar install (default is package from webupd8team/oracle)
 -o   : package install of openjdk 8

---------------------------------------------------"


while getopts 'hmo' opt; do
  case $opt in
    h) echo -e "$usage"
       exit
    ;;
    m) manual="true"
    ;;
    o) openjdk="true"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
        exit 1
    ;;
  esac
done

echo "Installing the JDK"
echo "---> install_java - dealing with apt.daily"
killall -9 apt apt-get apt-key
#
rm /var/lib/dpkg/lock
rm /var/lib/apt/lists/lock
rm /var/cache/apt/archives/lock
#
#dpkg --configure -a &
#dpkg_process_id=$!
#echo "dpkg_process_id $dpkg_process_id"

systemctl stop apt-daily.service
systemctl kill --kill-who=all apt-daily.service
echo "<--- install_java - apt.daily dealt with"



if [ -n "$openjdk" ]; then

  echo "Performing package OpenJDK install"

  apt-get -y update
  apt-get -y install openjdk-8-jdk 
  exit 0

fi
if [ -z "$manual" ]; then
  echo "Performing package Oracle install"
  # check for lock
  echo -e "Checking if apt/dpkg running, start: $(date +%r)"
  #while ps -A | grep -e apt -e dpkg >/dev/null 2>&1; do sleep 10s; done;
  end=150

  # install extra packages
  echo -e "Checking if apt/dpkg running, start: $(date +%r)"
  while [ $SECONDS -lt $end ]; do
   output=`ps -A | grep -e apt -e dpkg`
   if [ -z "$output" ]
   then
     break;
   fi
  done

  echo -e "No other procs: $(date +%r)"

  # Install add-apt-repository
  apt-get -y install software-properties-common

  add-apt-repository -y ppa:webupd8team/java
  #apt-get -y update
  echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
  echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
  apt-get -y install oracle-java8-installer

  # We're seeing Java installs fail intermittently.  Retrying indefinitely seems problematic.  I'm not sure
  # what the correct solution is.  For now, we're just going to run the install a second time.  This will do
  # nothing if the first install was successful and I suspect will eliminate the majority of our failures.
  apt-get -y install oracle-java8-installer
  exit 0
else
  echo "-m flag passed, performing manual tar install of Oracle JDK"
  url='http://download.oracle.com/otn-pub/java/jdk/8u162-b12/0da788060d494f5095bf8624735fa2f1/jdk-8u162-linux-x64.tar.gz'
  wget --no-cookies --no-check-certificate \
  --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" $url

  tar -xvf jdk-8u162-linux-x64.tar.gz -C /opt/
  # minimal update-alternatives calls
  update-alternatives --install /usr/bin/java java /opt/jdk1.8.0_162/bin/java 100
  update-alternatives --set java /opt/jdk1.8.0_162/bin/java
  update-alternatives --install /usr/bin/javac javac /opt/jdk1.8.0_162/bin/javac 100
  update-alternatives --set javac /opt/jdk1.8.0_162/bin/javac
  update-alternatives --install /usr/bin/keytool keytool /opt/jdk1.8.0_162/bin/keytool 100
  update-alternatives --set keytool /opt/jdk1.8.0_162/bin/keytool
  # remaining install
  update-alternatives --install /usr/bin/ControlPanel ControlPanel  /opt/jdk1.8.0_162/bin/ControlPanel 100
  update-alternatives --install /usr/bin/javaws javaws  /opt/jdk1.8.0_162/bin/javaws 100
  update-alternatives --install /usr/bin/jcontrol jcontrol  /opt/jdk1.8.0_162/bin/jcontrol 100
  update-alternatives --install /usr/bin/jjs jjs  /opt/jdk1.8.0_162/bin/jjs 100
  update-alternatives --install /usr/bin/orbd orbd  /opt/jdk1.8.0_162/bin/orbd 100
  update-alternatives --install /usr/bin/pack200 pack200  /opt/jdk1.8.0_162/bin/pack200 100
  update-alternatives --install /usr/bin/policytool policytool  /opt/jdk1.8.0_162/bin/policytool 100
  update-alternatives --install /usr/bin/rmid rmid  /opt/jdk1.8.0_162/bin/rmid 100
  update-alternatives --install /usr/bin/rmiregistry rmiregistry  /opt/jdk1.8.0_162/bin/rmiregistry 100
  update-alternatives --install /usr/bin/servertool servertool  /opt/jdk1.8.0_162/bin/servertool 100
  update-alternatives --install /usr/bin/tnameserv tnameserv  /opt/jdk1.8.0_162/bin/tnameserv 100
  update-alternatives --install /usr/bin/unpack200 unpack200  /opt/jdk1.8.0_162/bin/unpack200 100
  update-alternatives --install /usr/bin/jexec jexec  /opt/jdk1.8.0_162/jre/lib/jexec 100
  update-alternatives --install /usr/bin/appletviewer appletviewer  /opt/jdk1.8.0_162/bin/appletviewer 100
  update-alternatives --install /usr/bin/extcheck extcheck  /opt/jdk1.8.0_162/bin/extcheck 100
  update-alternatives --install /usr/bin/idlj idlj  /opt/jdk1.8.0_162/bin/idlj 100
  update-alternatives --install /usr/bin/jar jar  /opt/jdk1.8.0_162/bin/jar 100
  update-alternatives --install /usr/bin/jarsigner jarsigner  /opt/jdk1.8.0_162/bin/jarsigner 100
  update-alternatives --install /usr/bin/javadoc javadoc  /opt/jdk1.8.0_162/bin/javadoc 100
  update-alternatives --install /usr/bin/javafxpackager javafxpackager  /opt/jdk1.8.0_162/bin/javafxpackager 100
  update-alternatives --install /usr/bin/javah javah  /opt/jdk1.8.0_162/bin/javah 100
  update-alternatives --install /usr/bin/javap javap  /opt/jdk1.8.0_162/bin/javap 100
  update-alternatives --install /usr/bin/javapackager javapackager  /opt/jdk1.8.0_162/bin/javapackager 100
  update-alternatives --install /usr/bin/jcmd jcmd  /opt/jdk1.8.0_162/bin/jcmd 100
  update-alternatives --install /usr/bin/jconsole jconsole  /opt/jdk1.8.0_162/bin/jconsole 100
  update-alternatives --install /usr/bin/jdb jdb  /opt/jdk1.8.0_162/bin/jdb 100
  update-alternatives --install /usr/bin/jdeps jdeps  /opt/jdk1.8.0_162/bin/jdeps 100
  update-alternatives --install /usr/bin/jhat jhat  /opt/jdk1.8.0_162/bin/jhat 100
  update-alternatives --install /usr/bin/jinfo jinfo  /opt/jdk1.8.0_162/bin/jinfo 100
  update-alternatives --install /usr/bin/jmap jmap  /opt/jdk1.8.0_162/bin/jmap 100
  update-alternatives --install /usr/bin/jmc jmc  /opt/jdk1.8.0_162/bin/jmc 100
  update-alternatives --install /usr/bin/jps jps  /opt/jdk1.8.0_162/bin/jps 100
  update-alternatives --install /usr/bin/jrunscript jrunscript  /opt/jdk1.8.0_162/bin/jrunscript 100
  update-alternatives --install /usr/bin/jsadebugd jsadebugd  /opt/jdk1.8.0_162/bin/jsadebugd 100
  update-alternatives --install /usr/bin/jstack jstack  /opt/jdk1.8.0_162/bin/jstack 100
  update-alternatives --install /usr/bin/jstat jstat  /opt/jdk1.8.0_162/bin/jstat 100
  update-alternatives --install /usr/bin/jstatd jstatd  /opt/jdk1.8.0_162/bin/jstatd 100
  update-alternatives --install /usr/bin/jvisualvm jvisualvm  /opt/jdk1.8.0_162/bin/jvisualvm 100
  update-alternatives --install /usr/bin/native2ascii native2ascii  /opt/jdk1.8.0_162/bin/native2ascii 100
  update-alternatives --install /usr/bin/rmic rmic  /opt/jdk1.8.0_162/bin/rmic 100
  update-alternatives --install /usr/bin/schemagen schemagen  /opt/jdk1.8.0_162/bin/schemagen 100
  update-alternatives --install /usr/bin/serialver serialver  /opt/jdk1.8.0_162/bin/serialver 100
  update-alternatives --install /usr/bin/wsgen wsgen  /opt/jdk1.8.0_162/bin/wsgen 100
  update-alternatives --install /usr/bin/wsimport wsimport  /opt/jdk1.8.0_162/bin/wsimport 100
  update-alternatives --install /usr/bin/xjc xjc  /opt/jdk1.8.0_162/bin/xjc 100
  update-alternatives --install /usr/lib/mozilla/plugins/libjavaplugin.so mozilla-javaplugin.so  /opt/jdk1.8.0_162/jre/lib/amd64/libnpjp2.so 100
  # remaining set
  update-alternatives --set ControlPanel  /opt/jdk1.8.0_162/bin/ControlPanel
  update-alternatives --set javaws  /opt/jdk1.8.0_162/bin/javaws
  update-alternatives --set jcontrol  /opt/jdk1.8.0_162/bin/jcontrol
  update-alternatives --set jjs  /opt/jdk1.8.0_162/bin/jjs
  update-alternatives --set orbd  /opt/jdk1.8.0_162/bin/orbd
  update-alternatives --set pack200  /opt/jdk1.8.0_162/bin/pack200
  update-alternatives --set policytool  /opt/jdk1.8.0_162/bin/policytool
  update-alternatives --set rmid  /opt/jdk1.8.0_162/bin/rmid
  update-alternatives --set rmiregistry  /opt/jdk1.8.0_162/bin/rmiregistry
  update-alternatives --set servertool  /opt/jdk1.8.0_162/bin/servertool
  update-alternatives --set tnameserv  /opt/jdk1.8.0_162/bin/tnameserv
  update-alternatives --set unpack200  /opt/jdk1.8.0_162/bin/unpack200
  update-alternatives --set jexec  /opt/jdk1.8.0_162/jre/lib/jexec
  update-alternatives --set appletviewer  /opt/jdk1.8.0_162/bin/appletviewer
  update-alternatives --set extcheck  /opt/jdk1.8.0_162/bin/extcheck
  update-alternatives --set idlj  /opt/jdk1.8.0_162/bin/idlj
  update-alternatives --set jar  /opt/jdk1.8.0_162/bin/jar
  update-alternatives --set jarsigner  /opt/jdk1.8.0_162/bin/jarsigner
  update-alternatives --set javadoc  /opt/jdk1.8.0_162/bin/javadoc
  update-alternatives --set javafxpackager  /opt/jdk1.8.0_162/bin/javafxpackager
  update-alternatives --set javah  /opt/jdk1.8.0_162/bin/javah
  update-alternatives --set javap  /opt/jdk1.8.0_162/bin/javap
  update-alternatives --set javapackager  /opt/jdk1.8.0_162/bin/javapackager
  update-alternatives --set jcmd  /opt/jdk1.8.0_162/bin/jcmd
  update-alternatives --set jconsole  /opt/jdk1.8.0_162/bin/jconsole
  update-alternatives --set jdb  /opt/jdk1.8.0_162/bin/jdb
  update-alternatives --set jdeps  /opt/jdk1.8.0_162/bin/jdeps
  update-alternatives --set jhat  /opt/jdk1.8.0_162/bin/jhat
  update-alternatives --set jinfo  /opt/jdk1.8.0_162/bin/jinfo
  update-alternatives --set jmap  /opt/jdk1.8.0_162/bin/jmap
  update-alternatives --set jmc  /opt/jdk1.8.0_162/bin/jmc
  update-alternatives --set jps  /opt/jdk1.8.0_162/bin/jps
  update-alternatives --set jrunscript  /opt/jdk1.8.0_162/bin/jrunscript
  update-alternatives --set jsadebugd  /opt/jdk1.8.0_162/bin/jsadebugd
  update-alternatives --set jstack  /opt/jdk1.8.0_162/bin/jstack
  update-alternatives --set jstat  /opt/jdk1.8.0_162/bin/jstat
  update-alternatives --set jstatd  /opt/jdk1.8.0_162/bin/jstatd
  update-alternatives --set jvisualvm  /opt/jdk1.8.0_162/bin/jvisualvm
  update-alternatives --set native2ascii  /opt/jdk1.8.0_162/bin/native2ascii
  update-alternatives --set rmic  /opt/jdk1.8.0_162/bin/rmic
  update-alternatives --set schemagen  /opt/jdk1.8.0_162/bin/schemagen
  update-alternatives --set serialver  /opt/jdk1.8.0_162/bin/serialver
  update-alternatives --set wsgen  /opt/jdk1.8.0_162/bin/wsgen
  update-alternatives --set wsimport  /opt/jdk1.8.0_162/bin/wsimport
  update-alternatives --set xjc  /opt/jdk1.8.0_162/bin/xjc
  update-alternatives --set mozilla-javaplugin.so  /opt/jdk1.8.0_162/jre/lib/amd64/libnpjp2.so
fi
