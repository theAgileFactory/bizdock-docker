#!/bin/sh

cd /opt/
wget http://mirror.switch.ch/mirror/apache/dist/maven/maven-3/3.3.3/binaries/apache-maven-3.3.3-bin.zip
unzip apache-maven-3.3.3-bin.zip
mv apache-maven-3.3.3 maven
#Add JAVA_HOME
echo "export JAVA_HOME=/usr/lib/jvm/java-openjdk/" >> ~/.bashrc