#!/bin/sh

#Add JAVA_HOME
echo "export JAVA_HOME=/usr/lib/jvm/java-openjdk/" >> /etc/bashrc
#Add a variable for SBT
echo "export SBT_EXECUTABLE_NAME=activator" >> /etc/bashrc
#Modify the .bashrc for ensuring that activator and maven will be in the path at container startup
echo "export PATH=/opt/activator:/opt/maven/bin:$PATH" >> /etc/bashrc
#Extends SBT_OPTS (scala compilation is highly RAM consuming and could result in a stackoverflow)
echo "export SBT_OPTS=\"-Xms4096m -Xmx4096m -Xss4096k\"" >> /etc/bashrc
