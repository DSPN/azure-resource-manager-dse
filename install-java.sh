# Install Default OpenJDK 7
# apt-get -y install default-jre

# Install Oracle JDK
# add-apt-repository -y ppa:webupd8team/java
# apt-get -y update 
# echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
#echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
# apt-get -y install oracle-java7-installer

# Install Azul Zulu JDK
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0x219BD9C9
apt-add-repository -y "deb http://repos.azulsystems.com/ubuntu stable main"
apt-get -y update 
apt-get -y install zulu-8

