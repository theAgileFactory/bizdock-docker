#!/bin/bash

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

  #create script for mysqldump
  if [ ! -e /var/opt/db/cron/mysqldump_db.sh ]; then
    echo "export BACKUP_DIR=/var/opt/db/dumps/" > /var/opt/db/cron/mysqldump_db.sh
    echo "find \$BACKUP_DIR -name \"maf*\" -mtime +10 |xargs rm -rf" >> /var/opt/db/cron/mysqldump_db.sh
    echo "mysqldump -R -h localhost -u root -p$MYSQL_ROOT_PASSWORD $MYSQL_DATABASE | gzip > \$BACKUP_DIR/maf_\`date +%F\`.gz" >> /var/opt/db/cron/mysqldump_db.sh
    chmod +x /var/opt/db/cron/mysqldump_db.sh
  fi

  #crontab configuration
  if [ ! -e /var/opt/db/cron/crontabFile ]; then
    echo "#Backup maf DB" > /var/opt/db/cron/crontabFile
    echo "0 2 * * * /var/opt/db/cron/mysqldump_db.sh" >> /var/opt/db/cron/crontabFile
  fi
  chown -R $userName.$userName /var/opt/db/
  crontab /var/opt/db/cron/crontabFile
fi

service cron start

bash /docker-entrypoint.sh mysqld
