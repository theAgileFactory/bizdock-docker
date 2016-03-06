#!/bin/sh

HELP=$'Possible arguments : \n\t--help (-h)\n\t--package (-p)\n\t--configure (-i)\n'

# parameter and option handling
case "$1" in
    --help) echo "$HELP"
        ;;
    -h) echo "$HELP";
        ;;
    --package) echo "Package build: sources will be pulled if not yet available and built"; noBuild=false
        ;;
    -p) echo "Package build: sources will be pulled if not yet available and built"; noBuild=false
        ;;
    --configure) echo "Configure: the development environment is prepared but no build is run";noBuild=true
        ;;
    -c) echo "Configure: the development environment is prepared but no build is run";noBuild=true
        ;;
    *) echo "Unknown parameter $1.\n$HELP"; exit 0
        ;;
esac

#Copy the build script
cp /opt/prepare/build.sh /opt/artifacts/build.sh

#Pull the projects from github
#framework
if [ ! -d "/opt/artifacts/app-framework" ]; then
    mkdir /opt/artifacts/app-framework
    cd /opt/artifacts/app-framework
    git init
    git pull https://github.com/theAgileFactory/app-framework.git
fi

#data model
if [ ! -d "/opt/artifacts/maf-desktop-datamodel" ]; then
    mkdir /opt/artifacts/maf-desktop-datamodel
    cd /opt/artifacts/maf-desktop-datamodel
    git init
    git pull https://github.com/theAgileFactory/maf-desktop-datamodel.git
fi

#desktop application
if [ ! -d "/opt/artifacts/maf-desktop-app" ]; then
    mkdir /opt/artifacts/maf-desktop-app
    cd /opt/artifacts/maf-desktop-app
    git init
    git pull https://github.com/theAgileFactory/maf-desktop-app.git
fi

#Build the projects
if [ "$noBuild" = false ] ; then
    /opt/artifacts/build.sh --framework
    STATUS=$?
    if [ $STATUS -ne 0 ]; then
        exit 1
    fi
    exit 0
else 
   echo "The environment is now ready to be used, please run a new container with the same volumes in interactive mode (--entrypoint=/bin/bash) to use activator"
fi