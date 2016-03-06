#!/bin/sh
cd /opt
wget https://downloads.typesafe.com/typesafe-activator/1.3.7/typesafe-activator-1.3.7-minimal.zip
unzip typesafe-activator-1.3.7-minimal.zip
rm typesafe-activator-1.3.7-minimal.zip
mv activator-1.3.7-minimal activator
#Add a variable for SBT
echo "export SBT_EXECUTABLE_NAME=activator" >> ~/.bashrc