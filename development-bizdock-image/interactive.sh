#!/bin/sh

#Alternative entrypoint for the container
#This one must be used interactively with "-ti" parameters

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
	cd /opt/artifacts
	useradd -u $userUid $userName
	sudo -u $userName /tmp/update_bashrc.sh
	sudo -u $userName /bin/bash
else
	echo "No user UID provided, cannot securely user the development environment"
	exit 1
fi