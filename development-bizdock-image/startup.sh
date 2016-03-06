#!/bin/sh

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
	#Change the owner
	chown $userName.$userName /opt/artifacts/build.sh
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
	
	echo ">> The environment is now ready to be used interactively"
eof