#!/bin/sh

# This script creates minimal maf-file-system files and folders to have a running bizdock instance

if [ $# -ne 1 ]; then
  echo "Usage: $0 username"
  exit 1
fi

N=$(echo $(cat /opt/artifacts/maf-desktop-app/conf/framework.conf | grep saml.sso.config | cut -d '=' -f 2 | cut -d '"' -f 2 | grep -o "/" | wc -l)+1 | bc)
SSO_FILE=$(cat /opt/artifacts/maf-desktop-app/conf/framework.conf | grep saml.sso.config | cut -d '=' -f 2 | cut -d '"' -f 2 | cut -d '/' -f $N)
if [ ! -d /opt/artifacts/maf-file-system/$SSO_FILE ]; then
  touch /opt/artifacts/maf-file-system/$SSO_FILE
  chown $1.$1 /opt/artifacts/maf-file-system/$SSO_FILE
fi

N=$(cat /opt/artifacts/maf-desktop-app/conf/framework.conf | grep maf.personal.space.root | cut -d '=' -f 2 | cut -d '"' -f 2 | grep -o "/" | wc -l)
PERSONAL_SPACE_FOLDER=$(cat /opt/artifacts/maf-desktop-app/conf/framework.conf | grep maf.personal.space.root | cut -d '=' -f 2 | cut -d '"' -f 2 | cut -d '/' -f $N)
if [ ! -d /opt/artifacts/maf-file-system/$PERSONAL_SPACE_FOLDER ]; then
  mkdir -p /opt/artifacts/maf-file-system/$PERSONAL_SPACE_FOLDER
  chown $1.$1 /opt/artifacts/maf-file-system/$PERSONAL_SPACE_FOLDER
fi

N=$(cat /opt/artifacts/maf-desktop-app/conf/framework.conf | grep maf.report.custom.root | cut -d '=' -f 2 | cut -d '"' -f 2 | grep -o "/" | wc -l)
FTP_FOLDER=$(cat /opt/artifacts/maf-desktop-app/conf/framework.conf | grep maf.report.custom.root | cut -d '=' -f 2 | cut -d '"' -f 2 | cut -d '/' -f $N)
if [ ! -d /opt/artifacts/maf-file-system/$FTP_FOLDER ]; then
  mkdir -p /opt/artifacts/maf-file-system/$FTP_FOLDER
  chown $1.$1 /opt/artifacts/maf-file-system/$FTP_FOLDER
fi

N=$(cat /opt/artifacts/maf-desktop-app/conf/framework.conf | grep maf.attachments.root | cut -d '=' -f 2 | cut -d '"' -f 2 | grep -o "/" | wc -l)
ATTACHMENTS_FOLDER=$(cat /opt/artifacts/maf-desktop-app/conf/framework.conf | grep maf.attachments.root | cut -d '=' -f 2 | cut -d '"' -f 2 | cut -d '/' -f $N)
if [ ! -d /opt/artifacts/maf-file-system//opt/artifacts/maf-file-system/$ATTACHMENTS_FOLDER ]; then
  mkdir -p /opt/artifacts/maf-file-system/$ATTACHMENTS_FOLDER
  chown $1.$1 /opt/artifacts/maf-file-system/$ATTACHMENTS_FOLDER
fi

N=$(cat /opt/artifacts/maf-desktop-app/conf/framework.conf | grep maf.ext.directory | cut -d '=' -f 2 | cut -d '"' -f 2 | grep -o "/" | wc -l)
EXTENSIONS_FOLDER=$(cat /opt/artifacts/maf-desktop-app/conf/framework.conf | grep maf.ext.directory | cut -d '=' -f 2 | cut -d '"' -f 2 | cut -d '/' -f $N)
if [ ! -d /opt/artifacts/maf-file-system/$EXTENSIONS_FOLDER ]; then
  mkdir -p /opt/artifacts/maf-file-system/$EXTENSIONS_FOLDER
  chown $1.$1 /opt/artifacts/maf-file-system/$EXTENSIONS_FOLDER
fi

