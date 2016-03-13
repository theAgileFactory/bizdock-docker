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
else
   echo ">> No user provided as parameters for the script, using the default maf (uid = 1000) user instead (WARNING the resulting packages might not be accessible from the host)"
   userName="maf"
   userUid=1000
   useradd -u $userUid $userName
fi

source /etc/bashrc

#Copy the default configuration files
cp /opt/prepare/bizdockdb-dbmdl-framework.properties /opt/artifacts/bizdockdb-dbmdl-framework.properties
cp /opt/prepare/bizdockdb-maf-dbmdl.properties /opt/artifacts/bizdockdb-maf-dbmdl.properties
cp /opt/prepare/bizdock-packaging.properties /opt/artifacts/bizdock-packaging.properties

# ------------------------------
# Pull the projects from github
# ------------------------------

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

#bizdock packaging
if [ ! -d "/opt/artifacts/bizdock-packaging" ]; then
  echo ">> Initializing bizdock-packaging"
  mkdir /opt/artifacts/bizdock-packaging
  cd /opt/artifacts/bizdock-packaging
  git init
  git pull https://github.com/theAgileFactory/bizdock-packaging.git
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

# ------------------------------
# Build the projects
# ------------------------------

rm -rf /opt/artifacts/deploy
mkdir /opt/artifacts/deploy

echo ">> Building the replacer"
mvn -f /opt/artifacts/replacer/pom.xml clean install
STATUS=$?
if [ $STATUS -ne 0 ]; then
  exit 1
fi

echo ">> Building dbmdl-framework"
mvn -f /opt/artifacts/dbmdl-framework/pom.xml clean install
STATUS=$?
if [ $STATUS -ne 0 ]; then
  exit 1
fi
cd /opt/artifacts/dbmdl-framework/target
versionNumber=$(ls dbmdl-framework-*-properties.zip | grep -oP '(?<=dbmdl-framework-).*(?=-properties.zip)')
echo ">> Found version number for dbmdl-framework $versionNumber"
mvn com.agifac.deploy:replacer-maven-plugin:replace -Dsource=dbmdl-framework-$versionNumber.zip -Denv=/opt/artifacts/bizdockdb-dbmdl-framework.properties
mv /opt/artifacts/dbmdl-framework/target/$(ls merged-dbmdl-framework-*.zip) /opt/artifacts/deploy
  
echo ">> Building maf-dbmdl"
mvn -f /opt/artifacts/maf-dbmdl/pom.xml clean install
STATUS=$?
if [ $STATUS -ne 0 ]; then
	exit 1
fi
cd /opt/artifacts/maf-dbmdl/target
versionNumber=$(ls maf-dbmdl-*-properties.zip | grep -oP '(?<=maf-dbmdl-).*(?=-properties.zip)')
echo ">> Found version number for maf-dbmdl $versionNumber"
mvn com.agifac.deploy:replacer-maven-plugin:replace -Dsource=maf-dbmdl-$versionNumber.zip -Denv=/opt/artifacts/bizdockdb-maf-dbmdl.properties
mv /opt/artifacts/maf-dbmdl/target/$(ls merged-maf-dbmdl-*.zip) /opt/artifacts/deploy

echo ">> Building app-framework"
mvn -f /opt/artifacts/app-framework/pom.xml clean install
STATUS=$?
if [ $STATUS -ne 0 ]; then
  exit 1
fi

echo ">> Building maf-desktop-datamodel"
mvn -f /opt/artifacts/maf-desktop-datamodel/pom.xml clean install
STATUS=$?
if [ $STATUS -ne 0 ]; then
  exit 1
fi

echo ">> Building maf-desktop-app"
mvn -f /opt/artifacts/maf-desktop-app/pom.xml clean install
STATUS=$?
if [ $STATUS -ne 0 ]; then
  exit 1
fi

echo ">> Building bizdock packaging"
mvn -f /opt/artifacts/bizdock-packaging/pom.xml clean install
STATUS=$?
if [ $STATUS -ne 0 ]; then
  exit 1
fi
cd /opt/artifacts/bizdock-packaging/target
versionNumber=$(ls maf-desktop-*-properties.zip | grep -oP '(?<=maf-desktop-).*(?=-properties.zip)')
echo ">> Found version number for bizdock-packaging $versionNumber"
mvn com.agifac.deploy:replacer-maven-plugin:replace -Dsource=maf-desktop-$versionNumber.zip -Denv=/opt/artifacts/bizdock-packaging.properties
mv /opt/artifacts/bizdock-packaging/target/$(ls merged-maf-desktop-*.zip) /opt/artifacts/deploy

#Change the owner of the artifacts folder
chown -R $userName.$userName /opt/artifacts
#Change the owner of the build cache folder
chmod -R 777 /opt/cache

echo ">> The environment is now ready to be used interactively"
