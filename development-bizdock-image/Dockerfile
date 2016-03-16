FROM centos:7

#Volumes to store the artifacts once they are ready to be deployed
VOLUME /opt/artifacts
VOLUME /opt/cache/.m2
VOLUME /opt/cache/.ivy2
VOLUME /opt/cache/.sbt

#Create to the cache folders for root (the same is required for the selected user)
RUN mkdir -p /opt/cache/.m2;mkdir -p /opt/cache/.ivy2;chmod -R 777 /opt/cache;mkdir -p /opt/cache/.sbt;cd /root;ln -s /opt/cache/.m2 .m2;ln -s /opt/cache/.ivy2 .ivy2;ln -s /opt/cache/.sbt .sbt

#Expose the port if activator is launched (in order to run the application)
EXPOSE 9000

#Install the EPEL repository
RUN yum update -y && yum install -y --setopt=tsflags=nodocs epel-release && yum clean all

#Required packages
# java-1.8.0-openjdk-devel : full JDK to be able to run maven and compile BizDock
# sudo : required for running some scripts under a different user than root
# mariadb : SQL client to run some operations on the database
# git : the git client for pulling the source code
# wget : user to download activator and maven installations
# unzip : for unzipping various installations packages
# bc : for doing some computations in the shell
RUN yum install -y --setopt=tsflags=nodocs java-1.8.0-openjdk-devel sudo mariadb git wget unzip bc && yum clean all

#Install play
ADD install_play.sh /tmp/install_play.sh
RUN chmod u+x /tmp/install_play.sh;/tmp/install_play.sh

#Install maven
ADD install_maven.sh /tmp/install_maven.sh
RUN chmod u+x /tmp/install_maven.sh;/tmp/install_maven.sh

#Update bashrc
ADD update_bashrc.sh /tmp/update_bashrc.sh
RUN chmod +x+r /tmp/update_bashrc.sh;/tmp/update_bashrc.sh

# Edit sudoers file # To avoid error: sudo: sorry, you must have a tty to run sudo 
RUN sed -i -e "s/Defaults    requiretty.*/ #Defaults    requiretty/g" /etc/sudoers

#Default entrypoint script
ADD startup.sh /opt/prepare/startup.sh

#Alterative entrypoint for interactive mode
ADD interactive.sh /opt/prepare/interactive.sh

#Utility for building the source code
ADD build.sh /opt/prepare/build.sh
#Utility for managing the database
ADD db.sh /opt/prepare/db.sh
#Utility to create the bizdock file system
ADD create_maf_fs.sh /opt/prepare/create_maf_fs.sh

#Configuration for building the various components
ADD bizdockdb-dbmdl-framework.properties /opt/prepare/bizdockdb-dbmdl-framework.properties
ADD bizdockdb-maf-dbmdl.properties /opt/prepare/bizdockdb-maf-dbmdl.properties
ADD bizdock-packaging.properties /opt/prepare/bizdock-packaging.properties
ADD framework.conf /opt/prepare/framework.conf
ADD environment.conf /opt/prepare/environment.conf

RUN chmod u+x /opt/prepare/startup.sh;chmod u+x /opt/prepare/create_maf_fs.sh;chmod u+x /opt/prepare/interactive.sh;chmod u+x /opt/prepare/build.sh;chmod u+x /opt/prepare/db.sh

ENTRYPOINT ["/opt/prepare/startup.sh"]
