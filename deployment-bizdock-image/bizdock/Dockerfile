FROM centos:7

MAINTAINER Marc Schaer <marc.schar@the-agile-factory.com>

#Create volumes
VOLUME /opt/start-config/
VOLUME /opt/maf-file-system/

#epel-repo
RUN yum update -y && yum install -y --setopt=tsflags=nodocs epel-release && yum clean all

#Install required and useful packages
RUN yum install -y --setopt=tsflags=nodocs bc which unzip tar mariadb telnet wget curl bzip2 xz java-1.8.0-openjdk && yum clean all

RUN mkdir -p /opt/maf/maf-desktop/server
RUN mkdir -p /tmp/deadletters/ && mkdir -p /tmp/deadletters-reprocessing

#Add compiled files
ADD bizdock/*.zip /opt/maf/
RUN unzip /opt/maf/merged-dbmdl-framework-11.0.1-SNAPSHOT.zip -d /opt/maf/dbmdl-framework && chmod u+x /opt/maf/dbmdl-framework/scripts/*
RUN unzip /opt/maf/merged-maf-dbmdl-11.0.1-SNAPSHOT.zip -d /opt/maf/maf-dbmdl && chmod u+x /opt/maf/maf-dbmdl/scripts/*
RUN unzip /opt/maf/merged-maf-desktop-11.1.1-SNAPSHOT.zip -d /opt/maf/maf-desktop
RUN unzip /opt/maf/maf-desktop/play-apps/maf-desktop-app-dist.zip -d /opt/maf/maf-desktop/server && chmod u+x /opt/maf/maf-desktop/server/maf-desktop-app-dist/bin/maf-desktop-app

ADD bizdock/startup.sh bizdock/update_bashrc.sh /opt/scripts/

RUN chmod u+x /opt/scripts/startup.sh && chmod u+x /opt/scripts/update_bashrc.sh 

ENTRYPOINT [ "/opt/scripts/startup.sh" ]
