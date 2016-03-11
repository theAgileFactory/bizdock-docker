#!/bin/bash

#Default entrypoint for the container
#This one will configure the development environment for a first use

HELP="Possible arguments :
--help (-h)
--useruid (-g)   : the uid of the user which is using the development environment
--username (-u)  : the name of the user which is using the development environment"
while [[ $# > 0 ]]
do
  key="$1"
  case $key in
    -h|--help)
      echo $HELP
      exit 0
      ;;
    -u|--username)
      userName=$2
      shift
      ;;
    -g|--useruid)
      userUid=$2
      shift
      ;;
    *)
      echo "Unknown parameter $1 exiting"
      exit 1
      ;;
  esac
  shift
done

#Create a user with the right UID to allow access to the files from the host
if [[ ! -z "$userUid" ]] && [[ ! -z "$userName" ]]  ; then
  useradd -u $userUid $userName
  #Copy the build script
  cp /opt/prepare/build.sh /opt/artifacts/build.sh
  cp /opt/prepare/db.sh /opt/artifacts/db.sh
  cp /opt/prepare/bizdockdb-dbmdl-framework.properties /opt/artifacts/bizdockdb-dbmdl-framework.properties
  cp /opt/prepare/bizdockdb-maf-dbmdl.properties /opt/artifacts/bizdockdb-maf-dbmdl.properties
  mkdir -p /opt/artifacts/configuration_files
  if [ -z "$(ls /opt/artifacts/configuration_files)" ]; then
    cp /opt/prepare/configuration_files/* /opt/artifacts/configuration_files/ 
  fi

  if [ ! -d /opt/artifacts/maf-file-system ]; then
    mkdir -p /opt/artifacts/maf-file-system
  fi

  if [ ! -d /tmp/deadletters ]; then
    mkdir -p /tmp/deadletters
    mkdir -p /tmp/deadletters-reprocessing
  fi

  #Change the owner
  chown $userName.$userName /opt/artifacts/build.sh
  chown $userName.$userName /opt/artifacts/db.sh
  chown $userName.$userName /opt/artifacts/bizdockdb-dbmdl-framework.properties
  chown $userName.$userName /opt/artifacts/bizdockdb-maf-dbmdl.properties
  chown $userName.$userName /opt/artifacts/maf-file-system
  chown -R $userName.$userName /opt/artifacts/configuration_files
  chown -R $userName.$userName /opt/artifacts/maf-file-system
  chown $userName.$userName /opt/prepare/create_maf_fs.sh


else
  echo "No user UID provided, cannot securely create the development environment"
  exit 1
fi

#Change to the current user for enabling the appropriate permissions
exec sudo -u $userName /bin/sh - << eof
#Pull the projects from github
#framework
if [ ! -d "/opt/artifacts/app-framework" ]; then
  echo ">> Initializing app-framework"
  mkdir /opt/artifacts/app-framework
  cd /opt/artifacts/app-framework
  git init
  git pull https://github.com/theAgileFactory/app-framework.git
fi

#data model
if [ ! -d "/opt/artifacts/maf-desktop-datamodel" ]; then
  echo ">> Initializing app-maf-desktop-datamodel"
  mkdir /opt/artifacts/maf-desktop-datamodel
  cd /opt/artifacts/maf-desktop-datamodel
  git init
  git pull https://github.com/theAgileFactory/maf-desktop-datamodel.git
fi

#desktop application
if [ ! -d "/opt/artifacts/maf-desktop-app" ]; then
  echo ">> Initializing maf-desktop-app"
  mkdir /opt/artifacts/maf-desktop-app
  cd /opt/artifacts/maf-desktop-app
  git init
  git pull https://github.com/theAgileFactory/maf-desktop-app.git
fi

#dbmdl for the framework
if [ ! -d "/opt/artifacts/dbmdl-framework" ]; then
  echo ">> Initializing dbmdl-framework"
  mkdir /opt/artifacts/dbmdl-framework
  cd /opt/artifacts/dbmdl-framework
  git init
  git pull https://github.com/theAgileFactory/dbmdl-framework.git
fi

#dbmdl for the desktop
if [ ! -d "/opt/artifacts/maf-dbmdl" ]; then
  echo ">> Initializing maf-dbmdl"
  mkdir /opt/artifacts/maf-dbmdl
  cd /opt/artifacts/maf-dbmdl
  git init
  git pull https://github.com/theAgileFactory/maf-dbmdl.git
fi

#replacer (used for properties management)
if [ ! -d "/opt/artifacts/replacer" ]; then
  echo ">> Initializing replacer"
  mkdir /opt/artifacts/replacer
  cd /opt/artifacts/replacer
  git init
  git pull https://github.com/theAgileFactory/replacer.git
fi

if [ -e /opt/artifacts/configuration_files/application.conf ]; then
  cp /opt/artifacts/configuration_files/application.conf /opt/artifacts/maf-desktop-app/conf/
fi
if [ -e /opt/artifacts/configuration_files/application-logger.xml ]; then
  cp /opt/artifacts/configuration_files/application-logger.xml /opt/artifacts/maf-desktop-app/conf/
fi
if [ -e /opt/artifacts/configuration_files/environment.conf ]; then
  cp /opt/artifacts/configuration_files/environment.conf /opt/artifacts/maf-desktop-app/conf/
fi
if [ -e /opt/artifacts/configuration_files/framework.conf ]; then
  cp /opt/artifacts/configuration_files/framework.conf /opt/artifacts/maf-desktop-app/conf/
fi

/opt/prepare/create_maf_fs.sh $userName

echo ">> The environment is now ready to be used interactively"
eof
