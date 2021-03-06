#!/bin/sh

#This script provides some utilities to initialize or refresh the database with the last changes
#If "reset" is selected, the database schema will be droped before being re-created

HELP="Possible arguments :
--help (-h)
--reset (-r)   : reset the database (drop the current schema)
--initialize (-i) : include test data (to use with -r)"

resetDatabase=false
initDatabase=false
while [[ $# > 0 ]]
do
  key="$1"
  case $key in
    -h|--help)
      echo $HELP
      exit 0
      ;;
    -r|--reset)
      resetDatabase=true
      ;;
    -i|--initialize)
      initDatabase=true
      ;;
    *)
      echo "Unknown parameter $1 exiting"
      exit 1
      ;;
  esac
  shift
done

if [ "$resetDatabase" = true ] ; then
  echo ">> Reseting the database schema"
  mysql -h bizdockdb -u root --password=root <<EOF
DROP SCHEMA IF EXISTS maf;
CREATE SCHEMA IF NOT EXISTS maf 
DEFAULT CHARACTER SET utf8;
CREATE USER IF NOT EXISTS 'maf'@'%' IDENTIFIED BY 'maf';
GRANT ALL ON maf.* TO 'maf'@'%';
FLUSH PRIVILEGES;
EOF
  STATUS=$?
  if [ $STATUS -ne 0 ]; then
    exit 1
  fi
fi

echo "---- BUILDING REPLACER ----"
mvn -f /opt/artifacts/replacer/pom.xml clean install
STATUS=$?
if [ $STATUS -ne 0 ]; then
  exit 1
fi

echo "---- BUILDING FRAMEWORK ----"
mvn -f /opt/artifacts/dbmdl-framework/pom.xml clean install
STATUS=$?
if [ $STATUS -ne 0 ]; then
  exit 1
fi
cd /opt/artifacts/dbmdl-framework/target
versionNumber=$(ls dbmdl-framework-*-properties.zip | grep -oP '(?<=dbmdl-framework-).*(?=-properties.zip)')
mvn com.agifac.deploy:replacer-maven-plugin:replace -Dsource=dbmdl-framework-$versionNumber.zip -Denv=/opt/artifacts/bizdockdb-dbmdl-framework.properties
unzip -d script merged-dbmdl-framework-$versionNumber.zip
cd script/scripts
chmod u+x *.sh

echo "---- BUILDING MAF DBMDL ----"
mvn -f /opt/artifacts/maf-dbmdl/pom.xml clean install
STATUS=$?
if [ $STATUS -ne 0 ]; then
  exit 1
fi
cd /opt/artifacts/maf-dbmdl/target
versionNumber=$(ls maf-dbmdl-*-properties.zip | grep -oP '(?<=maf-dbmdl-).*(?=-properties.zip)')
mvn com.agifac.deploy:replacer-maven-plugin:replace -Dsource=maf-dbmdl-$versionNumber.zip -Denv=/opt/artifacts/bizdockdb-maf-dbmdl.properties
unzip -d script merged-maf-dbmdl-$versionNumber.zip
cd script/scripts
chmod u+x *.sh

echo "---- REFRESH DATABASE ----"
/opt/artifacts/dbmdl-framework/target/script/scripts/run.sh
STATUS=$?
if [ $STATUS -ne 0 ]; then
  exit 1
fi
/opt/artifacts/maf-dbmdl/target/script/scripts/run.sh
STATUS=$?
if [ $STATUS -ne 0 ]; then
  exit 1
fi

if [ "$resetDatabase" = true ] ; then
  echo ">> Initializing the database"
  mysql -h bizdockdb -u root --password=root maf < /opt/artifacts/maf-desktop-app/conf/sql/init_base.sql
  STATUS=$?
  if [ $STATUS -ne 0 ]; then
    exit 1
  fi
  if [ "$initDatabase" ]; then
    echo ">> Initializing test data"
    mysql -h bizdockdb -u root --password=root maf < /opt/prepare/init_data.sql
  fi
fi
