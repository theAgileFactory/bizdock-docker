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
RUN yum install -y --setopt=tsflags=nodocs java-1.8.0-openjdk-devel git wget unzip && yum clean all

#Install play
ADD install_play.sh /tmp/install_play.sh
RUN /tmp/install_play.sh

#Install maven
ADD install_maven.sh /tmp/install_maven.sh
RUN /tmp/install_maven.sh

#Modify the .bashrc for ensuring that activator and maven will be in the path at container startup
RUN echo "export PATH=/opt/activator:/opt/maven/bin:$PATH" >> ~/.bashrc

ADD startup.sh /opt/prepare/startup.sh
ADD build.sh /opt/prepare/build.sh
ENTRYPOINT ["/opt/prepare/startup.sh"]