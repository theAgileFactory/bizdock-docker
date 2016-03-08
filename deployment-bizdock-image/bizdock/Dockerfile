FROM centos:7

MAINTAINER Marc Schaer <marc.schar@the-agile-factory.com>

#Create volumes
VOLUME /opt/start-config

#Add startup scripts
ADD bizdock/startup.sh bizdock/merge_properties.sh /opt/scripts/

#epel-repo
RUN yum update -y && yum install -y --setopt=tsflags=nodocs epel-release && yum clean all

#Install required and useful packages
RUN yum install -y --setopt=tsflags=nodocs unzip tar MariaDB-client telnet wget curl bzip2 xz java-1.8.0-openjdk && yum clean all

#Add required users setup file system
RUN useradd -s /bin/bash maf && echo -e "export JAVA_HOME=/usr/java/default/jre\nexport JAVA_OPTS=\"-Xmx2048m"\" |tee -a /etc/bashrc /etc/profile && mkdir -p /opt/maf/maf-desktop/server

#Install play
ADD install_play.sh install_maven.sh /tmp/
RUN chmod u+x /tmp/install_play.sh;/tmp/install_play.sh && chmod u+x /tmp/install_maven.sh;/tmp/install_maven.sh

#Add compiled files
ADD bizdock/*.zip /opt/maf/

#Add properties files
ADD bizdock/bizdockdb-maf-dbmdl.properties bizdock/bizdockdb-dbmdl-framework.properties bizdock/bizdock-maf-desktop.properties /opt/start-config

#ADD merged-maf-dbmdl-11.0.1-SNAPSHOT.zip merged-maf-desktop-11.1.1-SNAPSHOT.zip merged-dbmdl-framework-11.0.1-SNAPSHOT.zip /root/docker/ 
#RUN unzip /root/docker/merged-maf-dbmdl-11.0.1-SNAPSHOT.zip -d /root/docker/maf-dbmdl && chmod u+x /root/docker/maf-dbmdl/scripts/*.sh
#RUN unzip /root/docker/merged-dbmdl-framework-11.0.1-SNAPSHOT.zip -d /root/docker/dbmdl-framework && chmod u+x /root/docker/dbmdl-framework/scripts/*.sh
#RUN mkdir -p /opt/maf/maf-desktop/ && unzip /root/docker/merged-maf-desktop-11.1.1-SNAPSHOT.zip -d /opt/maf/maf-desktop/ && chmod -R u+x /opt/maf/maf-desktop/scripts/*
#RUN mkdir -p /opt/maf/maf-desktop/server  && cd /opt/maf/maf-desktop/server/ && unzip /opt/maf/maf-desktop/play-apps/maf-desktop-app-dist.zip && chmod +x /opt/maf/maf-desktop/server/maf-desktop-app-dist/bin/maf-desktop-app && chown -R maf:maf /opt/maf/maf-desktop/

#ENTRYPOINT /opt/maf/maf-desktop/server/maf-desktop-app-dist/bin/maf-desktop-app -Dcom.agifac.appid=maf-desktop-docker -Dconfig.file=/opt/maf/maf-desktop/conf/application.conf -Dlogger.file=/opt/maf/maf-desktop/conf/application-logger.xml -Dhttp.port=8000 -DapplyEvolutions.default=false

ENTRYPOINT [ "/opt/scripts/startup.sh" ]
