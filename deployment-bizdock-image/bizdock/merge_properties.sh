#!/bin/sh

echo "---- CLONING REPLACER ----"
exec /bin/sh - << eof
 ## reducer (used for properties management)
 if [ ! -d "/opt/maf/replacer" ]; then
  echo ">> Initializing replacer"
  mkdir /opt/maf/replacer
  cd /opt/maf/replacer
  git init
  git pull https://github.com/theAgileFactory/replacer.git
 else
  cd /opt/maf/replacer
  git pull
 fi
eof

cd /opt/maf

echo "---- BUILDING REPLACER ----"
mvn -f /opt/maf/replacer/pom.xml clean install
STATUS=$?
if [ $STATUS -ne 0 ]; then
  exit 1
fi

echo "---- MERGING DBMDL-FRAMEWORK PROPERTIES ----"
versionNumber=$(ls dbmdl-framework-*-properties.zip | grep -oP '(?<=dbmdl-framework-).*(?=-properties.zip)')
mvn com.agifac.deploy:replacer-maven-plugin:replace -Dsource=dbmdl-framework-$versionNumber.zip -Denv=/opt/start-config/bizdockdb-dbmdl-framework.properties
unzip -d dbmdl-framework merged-dbmdl-framework-$versionNumber.zip
chmod u+x dbmdl-framework/scripts/*.sh

echo "---- BUILDING MAF DBMDL ----"
versionNumber=$(ls maf-dbmdl-*-properties.zip | grep -oP '(?<=maf-dbmdl-).*(?=-properties.zip)')
mvn com.agifac.deploy:replacer-maven-plugin:replace -Dsource=maf-dbmdl-$versionNumber.zip -Denv=/opt/maf/bizdockdb-maf-dbmdl.properties
unzip -d maf-dbmdl merged-maf-dbmdl-$versionNumber.zip
chmod u+x maf-dbmdl/scripts/*.sh

echo "---- BUILDING DESKTOP ----"
versionNumber=$(ls maf-desktop-*-properties.zip | grep -oP '(?<=maf-desktop-).*(?=-properties.zip)')
mvn com.agifac.deploy:replacer-maven-plugin:replace -Dsource=maf-desktop-$versionNumber.zip -Denv=/opt/maf/bizdock-maf-desktop.properties
unzip -d maf-desktop merged-maf-desktop-$versionNumber.zip
chmod -R u+x maf-desktop/scripts/*

cd /opt/maf/maf-desktop/server
unzip /opt/maf/maf-desktop/play-apps/maf-desktop-app-dist.zip
chmod +x /opt/maf/maf-desktop/server/maf-desktop-app-dist/bin/maf-desktop-app
chown -R maf:maf /opt/maf/maf-desktop/

echo "---- REFRESH DATABASE ----"
/opt/maf/dbmdl-framework-scripts/scripts/run.sh
STATUS=$?
if [ $STATUS -ne 0 ]; then
  exit 1
fi
/opt/maf/dbmdl-maf-scripts/scripts/run.sh
STATUS=$?
if [ $STATUS -ne 0 ]; then
  exit 1
fi

