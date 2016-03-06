#!/bin/sh

#Add JAVA_HOME
echo "export JAVA_HOME=/usr/lib/jvm/java-openjdk/" >> ~/.bashrc
#Add a variable for SBT
echo "export SBT_EXECUTABLE_NAME=activator" >> ~/.bashrc
#Modify the .bashrc for ensuring that activator and maven will be in the path at container startup
echo "export PATH=/opt/activator:/opt/maven/bin:$PATH" >> ~/.bashrc
