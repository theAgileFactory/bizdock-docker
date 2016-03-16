#!/bin/sh

#Alternative entrypoint for the container #This one must be used interactively with "-ti" parameters HELP="Possible arguments :
#	--help (-h)
#	--useruid (-g)   : the uid of the user which is using the development environment
#   --username (-u)  : the name of the user which is using the development environment"

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
else
   echo ">> No user provided as parameters for the script, using the default maf (uid = 1000) user instead (WARNING the resulting packages might not be accessible from the host)"
   userName="maf"
   userUid=1000
   useradd -u $userUid $userName
fi
cd /home/$userName
#Change the owner of the build cache folder
chmod -R 777 /opt/cache
ln -s /opt/cache/.m2 .m2
ln -s /opt/cache/.ivy2 .ivy2
ln -s /opt/cache/.sbt .sbt
chown $userName.$userName .m2 .ivy2 .sbt

#Change the owner of the content of the workspace
chown -R $userName.$userName /opt/artifacts

#Copy the build scripts and default configuration files
cp /opt/prepare/build.sh /opt/artifacts/build.sh
cp /opt/prepare/db.sh /opt/artifacts/db.sh
chown $userName.$userName /opt/artifacts/build.sh
chown $userName.$userName /opt/artifacts/db.sh

#create the bizdock folders (various folders required for the service to be executed correctly)
if [ ! -d /opt/artifacts/maf-file-system ]; then
  mkdir -p /opt/artifacts/maf-file-system
  chown -R $userName.$userName /opt/artifacts/maf-file-system
fi
if [ ! -d /tmp/deadletters ]; then
  mkdir -p /tmp/deadletters
  mkdir -p /tmp/deadletters-reprocessing
fi
chown $userName.$userName /opt/prepare/create_maf_fs.sh
/opt/prepare/create_maf_fs.sh $userName

#Run a bash for interactive build
sudo -u $userName /bin/bash
