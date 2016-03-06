#!/bin/sh

#This script performs a full rebuild of the various components of the application (framework, datamodel, etc.)

OPTS=`getopt -a -o h -l help -o f -l framework -o m -l model -o d -l desktop -- "$0" "$@"`
HELP=$'Possible arguments : \n\t--help (-h)\n\t--framework (-f)\n\t--model (-m)\n\t--desktop (-d)\nOnly one option can be used because the --framework option will compile everything while --model will only compile model and desktop'

# Functions definition 

Framework () {
  echo "---- BUILDING FRAMEWORK ----"
  mvn -f /opt/artifacts/app-framework/pom.xml clean install
  STATUS=$?
  if [ $STATUS -ne 0 ]; then
    exit 1
  fi
  mvn -f /opt/artifacts/app-framework/pom.xml play2:eclipse
  STATUS=$?
  if [ $STATUS -ne 0 ]; then
    exit 1
  fi
  Model
}

Model () {
  echo "---- BUILDING DATA MODEL ----"
  mvn -f /opt/artifacts/maf-desktop-datamodel/pom.xml clean install
  STATUS=$?
  if [ $STATUS -ne 0 ]; then
    exit 1
  fi
  mvn -f /opt/artifacts/maf-desktop-datamodel/pom.xml play2:eclipse
  STATUS=$?
  if [ $STATUS -ne 0 ]; then
    exit 1
  fi
  sleep 5
  Desktop
}

Desktop () {
  echo "---- BUILDING DESKTOP ----"
  mvn -f /opt/artifacts/maf-desktop-app/pom.xml clean install
  STATUS=$?
  if [ $STATUS -ne 0 ]; then
    exit 1
  fi
  mvn -f /opt/artifacts/maf-desktop-app/pom.xml play2:eclipse
  STATUS=$?
  if [ $STATUS -ne 0 ]; then
    exit 1
  fi
}

End () {
  if [ -n "$1" ];then
    echo "$1 is not a valid argument. See -h for help.";
  fi
}

if [ "$#" -gt 1 ]; then
  echo "$HELP"
  exit 1
fi

if [ "$#" -eq 0 ]; then
  Framework
  exit 0
fi

if [ $? != 0 ] # There was an error parsing the options
then
  echo "Unkown option $1"
  exit 1 
fi

eval set -- "$OPTS"

# Process the arguments
while true; do
  case "$1" in
    --help) echo "$HELP"; shift;;
    -h) echo "$HELP"; shift;;
    --framework) Framework; #Call the Framework function
      shift;;
    -f) Framework; #Call the Framework function
      shift;;
    --model) Model; #Call the Model function
      shift;;
    -m) Model; #Call the Model function
      shift;;
    --desktop) Desktop; #Call the Desktop function
      shift;;
    -d) Desktop; #Call the Desktop function
      shift;;
    --) End $3; #Call the End function
      shift; break;;
  esac
done