#!/bin/sh

echo "---- MERGING PROPERTIES ----"
/opt/scripts/merge_properties.sh

echo "---- LAUNCHING BIZDOCK ----"
/opt/maf/maf-desktop/server/maf-desktop-app-dist/bin/maf-desktop-app -Dcom.agifac.appid=maf-desktop-docker -Dconfig.file    =/opt/maf/maf-desktop/conf/application.conf -Dlogger.file=/opt/maf/maf-desktop/conf/application-logger.xml -Dhttp.port=8000 -DapplyE    volutions.default=false
