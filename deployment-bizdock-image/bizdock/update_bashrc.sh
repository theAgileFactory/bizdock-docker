#!/bin/sh

#Add JAVA_HOME
echo -e "export JAVA_HOME=/usr/java/default/jre\nexport JAVA_OPTS=\"-Xmx2048m"\" |tee -a /etc/bashrc /etc/profile /root/.bashrc
