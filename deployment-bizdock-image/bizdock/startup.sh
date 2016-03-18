#!/bin/bash

set -e

#Default entrypoint for the container
#This one will configure the development environment for a first use

HELP="Possible arguments :
--help (-h)
--useruid (-g)   : the uid of the user which is using the development environment
--username (-u)  : the name of the user which is using the development environment
--port (-p)      : the BizDock port"

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
    -p|--port)
      BIZDOCK_PORT=$2
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
  user=$(id -u $userName > /dev/null 2>&1; echo $?)
  if [ $? -eq 0 ]; then
    useradd -u $userUid $userName
  fi

  /opt/scripts/update_bashrc.sh

  START_CONFIG=$(find "/opt/start-config" -type f -exec echo Found file {} \;)
  if [ -z "$START_CONFIG" ]; then
    mkdir /opt/start-config/dbmdl-framework && cp /opt/maf/dbmdl-framework/repo/environments/* /opt/start-config/dbmdl-framework
    mkdir /opt/start-config/maf-dbmdl && cp /opt/maf/maf-dbmdl/repo/environments/* /opt/start-config/maf-dbmdl
    mkdir /opt/start-config/maf-desktop && cp /opt/maf/maf-desktop/conf/*.conf /opt/start-config/maf-desktop && cp /opt/maf/maf-desktop/conf/*.xml /opt/start-config/maf-desktop
    chown -R $userName.$userName /opt/start-config/
  else
    cp /opt/start-config/dbmdl-framework/deploy.properties /opt/maf/dbmdl-framework/repo/environments
    cp /opt/start-config/dbmdl-framework/development.properties /opt/maf/dbmdl-framework/repo/environments
    cp /opt/start-config/maf-dbmdl/deploy.properties /opt/maf/maf-dbmdl/repo/environments
    cp /opt/start-config/maf-dbmdl/development.properties /opt/maf/maf-dbmdl/repo/environments
    cp /opt/start-config/maf-desktop/*.conf /opt/maf/maf-desktop/server/maf-desktop-app-dist/conf && cp /opt/start-config/maf-desktop/*.xml /opt/maf/maf-desktop/server/maf-desktop-app-dist/conf
    cp /opt/start-config/maf-desktop/*.conf /opt/maf/maf-desktop/conf && cp /opt/start-config/maf-desktop/*.xml /opt/maf/maf-desktop/conf
  fi
  if [ "$CONFIGURE_DB_INIT" = true ]; then
    #FIXME
echo ">> Reseting the database schema"
mysql -h bizdockdb -u root --password=root <<EOF
DROP SCHEMA IF EXISTS maf;
CREATE SCHEMA IF NOT EXISTS maf 
DEFAULT CHARACTER SET utf8;
CREATE USER IF NOT EXISTS 'maf'@'%' IDENTIFIED BY 'maf';
GRANT ALL ON maf.* TO 'maf'@'%';
EOF
  fi

  echo "---- REFRESH DATABASE ----"
  /opt/maf/dbmdl-framework/scripts/run.sh
  STATUS=$?
  if [ $STATUS -ne 0 ]; then
    exit 1
  fi
  /opt/maf/maf-dbmdl/scripts/run.sh
  STATUS=$?
  if [ $STATUS -ne 0 ]; then
    exit 1
  fi

  if [ "$CONFIGURE_DB_INIT" = true ]; then
    mysql -h bizdockdb -u root --password=root maf < /opt/maf/maf-desktop/server/maf-desktop-app-dist/conf/sql/init_base.sql
  fi

  N=$(echo $(cat /opt/start-config/maf-desktop/framework.conf | grep saml.sso.config | cut -d '=' -f 2 | cut -d '"' -f 2 | grep -o "/" | wc -l)+1 | bc)
  SSO_FILE=$(cat /opt/start-config/maf-desktop/framework.conf | grep saml.sso.config | cut -d '=' -f 2 | cut -d '"' -f 2 | cut -d '/' -f $N)
  if [ ! -d /opt/artifacts/maf-file-system/$SSO_FILE ]; then
    touch /opt/artifacts/maf-file-system/$SSO_FILE
  fi

  N=$(cat /opt/start-config/maf-desktop/framework.conf | grep maf.personal.space.root | cut -d '=' -f 2 | cut -d '"' -f 2 | grep -o "/" | wc -l)
  PERSONAL_SPACE_FOLDER=$(cat /opt/start-config/maf-desktop/framework.conf | grep maf.personal.space.root | cut -d '=' -f 2 | cut -d '"' -f 2 | cut -d '/' -f $N)
  if [ ! -d /opt/artifacts/maf-file-system/$PERSONAL_SPACE_FOLDER ]; then
    mkdir -p /opt/artifacts/maf-file-system/$PERSONAL_SPACE_FOLDER
  fi

  N=$(cat /opt/start-config/maf-desktop/framework.conf | grep maf.report.custom.root | cut -d '=' -f 2 | cut -d '"' -f 2 | grep -o "/" | wc -l)
  FTP_FOLDER=$(cat /opt/start-config/maf-desktop/framework.conf | grep maf.report.custom.root | cut -d '=' -f 2 | cut -d '"' -f 2 | cut -d '/' -f $N)
  if [ ! -d /opt/artifacts/maf-file-system/$FTP_FOLDER ]; then
    mkdir -p /opt/artifacts/maf-file-system/$FTP_FOLDER
  fi

  N=$(cat /opt/start-config/maf-desktop/framework.conf | grep maf.attachments.root | cut -d '=' -f 2 | cut -d '"' -f 2 | grep -o "/" | wc -l)
  ATTACHMENTS_FOLDER=$(cat /opt/start-config/maf-desktop/framework.conf | grep maf.attachments.root | cut -d '=' -f 2 | cut -d '"' -f 2 | cut -d '/' -f $N)
  if [ ! -d /opt/artifacts/maf-file-system//opt/artifacts/maf-file-system/$ATTACHMENTS_FOLDER ]; then
    mkdir -p /opt/artifacts/maf-file-system/$ATTACHMENTS_FOLDER
  fi

  N=$(cat /opt/start-config/maf-desktop/framework.conf | grep maf.ext.directory | cut -d '=' -f 2 | cut -d '"' -f 2 | grep -o "/" | wc -l)
  EXTENSIONS_FOLDER=$(cat /opt/start-config/maf-desktop/framework.conf | grep maf.ext.directory | cut -d '=' -f 2 | cut -d '"' -f 2 | cut -d '/' -f $N)
  if [ ! -d /opt/artifacts/maf-file-system/$EXTENSIONS_FOLDER ]; then
    mkdir -p /opt/artifacts/maf-file-system/$EXTENSIONS_FOLDER
  fi

  if [ ! -d /opt/artifacts/maf-file-system/outputs ]; then
    mkdir -p /opt/artifacts/maf-file-system/outputs
  fi

  if [ ! -d /opt/artifacts/maf-file-system/inputs ]; then
    mkdir -p /opt/artifacts/maf-file-system/inputs
  fi

  chown -R $userName.$userName /opt/artifacts/maf-file-system/

  echo "---- LAUNCHING BIZDOCK APPLICATION ----"
  /opt/maf/maf-desktop/server/maf-desktop-app-dist/bin/maf-desktop-app -Dcom.agifac.appid=maf-desktop-docker -Dconfig.file=/opt/maf/maf-desktop/server/maf-desktop-app-dist/conf/application.conf -Dlogger.file=/opt/maf/maf-desktop/server/maf-desktop-app-dist/conf/application-logger.xml -Dhttp.port=$BIZDOCK_PORT -DapplyEvolutions.default=false
else
  echo "You should use a valid user"
fi

