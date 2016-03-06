FROM centos:7

#Volumes to store the artifacts once they are ready to be deployed
VOLUME /opt/artifacts
VOLUME /root/.m2
VOLUME /root/.ivy2
VOLUME /root/.sbt

#Expose the port if activator is launched (in order to run the application)
EXPOSE 9000

#Install the EPEL repository
RUN yum update -y && yum install -y --setopt=tsflags=nodocs epel-release && yum clean all

#Required packages
RUN yum install -y --setopt=tsflags=nodocs java-1.8.0-openjdk-devel sudo git wget unzip && yum clean all

#Install play
ADD install_play.sh /tmp/install_play.sh
RUN chmod u+x /tmp/install_play.sh;/tmp/install_play.sh

#Install maven
ADD install_maven.sh /tmp/install_maven.sh
RUN chmod u+x /tmp/install_maven.sh;/tmp/install_maven.sh

#Install update bashrc
ADD update_bashrc.sh /tmp/update_bashrc.sh
RUN chmod +x+r /tmp/update_bashrc.sh;/tmp/update_bashrc.sh

# Edit sudoers file # To avoid error: sudo: sorry, you must have a tty to run sudo 
RUN sed -i -e "s/Defaults    requiretty.*/ #Defaults    requiretty/g" /etc/sudoers

ADD startup.sh /opt/prepare/startup.sh
ADD interactive.sh /opt/prepare/interactive.sh
ADD build.sh /opt/prepare/build.sh
RUN chmod u+x /opt/prepare/startup.sh;chmod u+x /opt/prepare/interactive.sh;chmod u+x /opt/prepare/build.sh
ENTRYPOINT ["/opt/prepare/startup.sh"]