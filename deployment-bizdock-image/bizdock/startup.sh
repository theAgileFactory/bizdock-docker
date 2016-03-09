#!/bin/bash

set -e

/opt/scripts/update_bashrc.sh

START_CONFIG=$(find "/opt/start-config" -type f -exec echo Found file {} \;)
if [ -z "$START_CONFIG" ]; then
  mkdir /opt/start-config/dbmdl-framework && cp /opt/maf/dbmdl-framework/repo/environments/* /opt/start-config/dbmdl-framework
  mkdir /opt/start-config/maf-dbmdl && cp /opt/maf/maf-dbmdl/repo/environments/* /opt/start-config/maf-dbmdl
  mkdir /opt/start-config/maf-desktop && cp /opt/maf/maf-desktop/conf/*.conf /opt/start-config/maf-desktop && cp /opt/maf/maf-desktop/conf/*.xml /opt/start-config/maf-desktop
else
  cp /opt/start-config/dbmdl-framework/deploy.properties /opt/maf/dbmdl-framework/repo/environments
  cp /opt/start-config/dbmdl-framework/development.properties /opt/maf/dbmdl-framework/repo/environments
  cp /opt/start-config/maf-dbmdl/deploy.properties /opt/maf/maf-dbmdl/repo/environments
  cp /opt/start-config/maf-dbmdl/development.properties /opt/maf/maf-dbmdl/repo/environments
  cp /opt/start-config/maf-desktop/*.conf /opt/maf/maf-desktop/server/maf-desktop-app-dist/conf && cp /opt/start-config/maf-desktop/*.xml /opt/maf/maf-desktop/server/maf-desktop-app-dist/conf
fi

if [ "$CONFIGURE_DB_INIT" = true ]; then
  echo ">> Reseting the database schema"
  mysql -h bizdock_db -u root --password=root <<EOF                                             
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
  mysql -h bizdock_db -u root --password=root maf < /opt/maf/maf-desktop/server/maf-desktop-app-dist/conf/sql/init_base.sql
fi

SSO_FOLDER=$(cat /opt/start-config/maf-desktop/framework.conf | grep saml.sso.config | grep -oP '(?<=="/opt/maf-file-system/).*?(?=/"|")')
if [ ! -d /opt/maf-file-system/$SSO_FOLDER ]; then
  mkdir -p /opt/maf-file-system/$SSO_FOLDER
fi

PERSONAL_SPACE_FOLDER=$(cat /opt/start-config/maf-desktop/framework.conf | grep maf.personal.space.root | grep -oP '(?<=="/opt/maf-file-system/).*?(?=/"|")')
if [ ! -d /opt/maf-file-system/$PERSONAL_SPACE_FOLDER ]; then
  mkdir -p /opt/maf-file-system/$PERSONAL_SPACE_FOLDER
fi

FTP_FOLDER=$(cat /opt/start-config/maf-desktop/framework.conf | grep maf.report.custom.root | grep -oP '(?<=="/opt/maf-file-system/).*?(?=/"|")')
if [ ! -d /opt/maf-file-system/$FTP_FOLDER ]; then
  mkdir -p /opt/maf-file-system/$FTP_FOLDER
fi

ATTACHMENTS_FOLDER=$(cat /opt/start-config/maf-desktop/framework.conf | grep maf.attachments.root | grep -oP '(?<=="/opt/maf-file-system/).*?(?=/"|")')
if [ ! -d /opt/maf-file-system/$ATTACHMENTS_FOLDER ]; then
  mkdir -p /opt/maf-file-system/$ATTACHMENTS_FOLDER
fi

EXTENSIONS_FOLDER=$(cat /opt/start-config/maf-desktop/framework.conf | grep maf.ext.directory | grep -oP '(?<=="/opt/maf-file-system/).*?(?=/"|")')
if [ ! -d /opt/maf-file-system/$EXTENSIONS_FOLDER ]; then
  mkdir -p /opt/maf-file-system/$EXTENSIONS_FOLDER
fi

echo "---- LAUNCHING BIZDOCK APPLICATION ----"
/opt/maf/maf-desktop/server/maf-desktop-app-dist/bin/maf-desktop-app -Dcom.agifac.appid=maf-desktop-docker -Dconfig.file=/opt/maf/maf-desktop/server/maf-desktop-app-dist/conf/application.conf -Dlogger.file=/opt/maf/maf-desktop/server/maf-desktop-app-dist//conf/application-logger.xml -Dhttp.port=9999 -DapplyEvolutions.default=false
