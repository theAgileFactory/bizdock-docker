#!/bin/sh

#This script is to be used to install and use the BizDock development environment

HELP=$'Possible arguments :\n\t--help (-h)\n\t--configure (-c)\t: configure the development environment (launch the first time)\n\t--interactive (-i)\t: open in interactive mode\n\t--workspace (-w)\t: the host folder in which the source code must be set\n\t--port (-p)\t\t: the port to which bizdock will listen (default is 8080)\n\t--no-database (-d)\t: do not run a database container'

bizDockPort=8080
noDatabase=false
while [[ $# > 0 ]]
do
	key="$1"
	case $key in
	    -h|--help)
	    	echo "$HELP"
	    	exit 0
	    ;;
	    -c|--configure)
	    	isConfigure=true
	    ;;
	    -i|--interactive)
	    	isInteractive=true
	    ;;
	    -d|--no-database)
	    	noDatabase=true
	    ;;
	    -w|--workspace)
	    	workspace=$2
	    	shift
	    ;;
	    -p|--port)
	    	bizDockPort=$2
	        shift
	    ;;
	    *)
	        echo "Unknown parameter $1 exiting"
	        exit 1
	    ;;
	esac
	shift
done

#Check if the workspace is correct
if [ ! "$workspace" ] ; then
	echo ">> No development workspace provided, exiting"
	exit 1
fi
if [ ! -d "$workspace" ]; then
	echo ">> Workspace [$workspace] is not valid, please check if the directory exists and is accessible"
	exit 1
fi

#Create a network
if [ ! "$(docker network ls | grep bizdock)" ] ; then
	echo ">> Creating a network for the BizDock containers"
	docker network create bizdock
fi

#Create the volumes
#These volumes are used to cache the various repositories used by BizDock
docker volume create --name=bizdock_mvnrepo
docker volume create --name=bizdock_ivyrepo
docker volume create --name=bizdock_sbtcache
docker volume create --name=bizdock_database

#Environment configuration
if [ "$isConfigure" = true ] ; then
	echo ">> Container launch in configuration mode"
	docker run --net=bizdock --rm --name=bizdockdev -v bizdock_sbtcache:/root/.sbt -v bizdock_ivyrepo:/root/.ivy2 -v bizdock_mvnrepo:/root/.m2 -v $workspace:/opt/artifacts taf/dev-app --useruid $(id -u $(whoami)) --username $(whoami)
else
	if [ "$isInteractive" = true ] ; then
		if [ "$noDatabase" = false ] ; then
			echo ">> Starting a database container for bizdock"
			docker run -d --net=bizdock --name=bizdockdb -v  bizdock_database:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=root mariadb:10.1 || echo ">> Cannot start the database container (named "bizdockdb"), this one is probably already running"
			echo ">> WARNING: the database container (named "bizdockdb") must be stopped manually"
		fi
		echo ">> Container launched in interactive mode"
		docker run --net=bizdock --rm --name=bizdockdev -ti -p $bizDockPort:9000 -v bizdock_sbtcache:/root/.sbt -v bizdock_ivyrepo:/root/.ivy2  -v bizdock_mvnrepo:/root/.m2 -v $workspace:/opt/artifacts --entrypoint=/opt/prepare/interactive.sh taf/dev-app --useruid $(id -u $(whoami)) --username $(whoami)
	else
		echo "$HELP"
	fi
fi
