#!/bin/sh

HELP=$'Available options: \n\t-P - main Bizdock port\n\t-d - start a basic database container with defaults options\n\t-s - database schema (name of the database)\n\t-u - database user\n\t-p - database password\n\t-b - Path to store db backup\n\t-H - database host and port in case the db is not set up as a docker instance (ex. HOST:PORT)\n\t-c - mount point for configuration files\n\t-m - optional mount of the maf-file-system volume on the host\n\t-h - help\n\t-i - initialize database' 

DB_NAME_DEFAULT='maf'
DB_USER_DEFAULT='maf'
DB_USER_PASSWD_DEFAULT='maf'
DB_NAME=
DB_USER=
DB_USER_PASSWD=
DB_HOST=""
CONFIG_VOLUME=
BIZDOCK_PORT=9999
BIZDOCK_PORT_DEFAULT=9999
DISTANT_DB=false
CONFIGURE_DB=false

if [ $? != 0 ] # There was an error parsing the options
then
  echo "Unkown option $1"
  echo "$HELP"
  exit 1 
fi

# Process the arguments
while getopts ":P:ds:u:p:H:c:m:b:hi" option
do
  case $option in
    P)
      BIZDOCK_PORT="$OPTARG"
      ;;
    d)
      DB_USER="$DB_USER_DEFAULT"
      DB_USER_PASSWD="$DB_USER_PASSWD_DEFAULT"
      ;;
    s)
      if [ -z "$DB_NAME" ]; then
        DB_NAME="$OPTARG"
      fi
      ;;
    b)
      DB_BACKUP="$OPTARG"
      if [ ! -d "$DB_BACKUP" ]; then
        echo ">> $DB_BACKUP does not exist. Please create it."
        exit 1
      fi
      ;;
    u)
      if [ -z "$DB_USER" ]; then
        DB_USER="$OPTARG"
      else
        DB_USER=$DB_USER_DEFAULT
      fi
      ;;
    p)
      if [ -z "$DB_USER_PASSWD" ]; then
        DB_USER_PASSWD="$OPTARG"
      else
        DB_USER_PASSWD=$DB_USER_PASSWD_DEFAULT
      fi
      ;;
    H)
      if [ -z "$DB_HOST" ]; then
        DB_HOST="$OPTARG"
        TEMP_HOST=$(echo "$DB_HOST" | egrep -e '[a-zA-Z]+[a-zA-Z0-9]+:[0-9]+')
        if [ "$TEMP_HOST" != "$DB_HOST" ]; then
          echo "The host must have the format HOST:PORT"
          exit 1;
        fi
        DB_HOST="-p $DB_HOST"
        DISTANT_DB=true
      else
        DISTANT_DB=false
        DB_HOST=""
      fi
      ;;
    m)
      MAF_FS="$OPTARG"
      if [ ! -d "$MAF_FS" ]; then
        echo ">> $MAF_FS does not exist. Please create it."
        exit 1
      fi
      MAF_FS="-v $MAF_FS:/opt/maf-file-system/"
      ;;
    c)
      CONFIG_VOLUME="$OPTARG"
      if [ ! -d "$CONFIG_VOLUME" ]; then
        echo ">> $CONFIG_VOLUME does not exist. Please create it."
        exit 1
      fi
      CONFIG_VOLUME="-v $CONFIG_VOLUME:/opt/start-config/"
      ;;
    h)
      echo "$HELP"
      exit 0
      ;;
    i)
      CONFIGURE_DB=true
      ;;
    :)
      echo "Option -$OPTARG needs an argument"
      exit 1
      ;;
    \?)
      echo "$OPTARG : invalid option"
      exit 1
      ;;
  esac
done


#Set defaults if needed
if [ -z "$DB_NAME" ]; then
  DB_NAME=$DB_NAME_DEFAULT
fi
if [ -z "$DB_USER" ]; then
  DB_USER=$DB_USER_DEFAULT
fi
if [ -z "$DB_USER_PASSWD" ]; then
  DB_USER_PASSWD=$DB_USER_PASSWD_DEFAULT
fi
if [ -z "$CONFIG_VOLUME" ]; then
  CONFIG_VOLUME="-v /opt/start-config/"
fi
if [ -z "$MAF_FS" ]; then
  MAF_FS="-v /opt/maf-file-system/"
fi
if [ -z "$DB_BACKUP" ]; then
  DB_BACKUP="-v /opt/bizdock-db-backups/"
fi


#Create network
NETWORK_TEST=$(docker network ls | grep bizdock_network)
if [ $? -eq 1 ]; then
  echo "---- NETWORK CREATION ----"
  docker network create bizdock_network
fi


#Create volumes
VOLUME_TEST=$(docker volume ls | grep bizdock_backups)
if [ $? -eq 1 ]; then
  docker volume create --name=bizdock_backups
fi


#Run Bizdock Database
if [ "$DISTANT_DB" = "false" ]; then
  docker volume create --name=bizdock_database

  INSTANCE_TEST=$(docker ps -a | grep -e "bizdock_db$")
  if [ $? -eq 1 ]; then
    echo "---- RUNNING DATABASE CONTAINER ----"
    echo ">> By default, the database dump is done every day at 2 am."
    echo ">> To change that, please create a 'startup.sh' script in $DB_BACKUP that adds a crontab file"
    echo ">>You can start from the default file in $DB_BACKUP"
    docker run --name=bizdock_db -d --net=bizdock_network $DB_HOST \
      -v bizdock_database:/var/lib/mysql/ \
      -v $DB_BACKUP:/var/opt/backups/ \
      -e MYSQL_ROOT_PASSWORD=root \
      -e MYSQL_DATABASE="$DB_NAME" \
      -e MYSQL_USER="$DB_USER" \
      -e MYSQL_PASSWORD="$DB_USER_PASSWD" \
      taf/bizdock_mariadb:10.1.12 --useruid $(id -u $(whoami)) --username $(whoami)

  fi
else
  echo "/!\\ Connection to a distant DB through properties files /!\\"
fi

# TODO : use docker compose to manage deployment
#wait 5 seconds to give time to DB to start correctly before bizdock
sleep 5

#Run Bizdock
echo "---- RUNNING BIZDOCK ----"
INSTANCE_TEST=$(docker ps -a | grep -e "bizdock$")
if [ $? -eq 1 ]; then
  docker run --name=bizdock -d --net=bizdock_network -p $BIZDOCK_PORT:$BIZDOCK_PORT_DEFAULT \
   -v /var/opt \
   -v /opt/mysqldump \
   $CONFIG_VOLUME \
   $MAF_FS \
   -e CONFIGURE_DB_INIT=$CONFIGURE_DB \
   taf/bizdock:11.0.1 --useruid $(id -u $(whoami)) --username $(whoami)
else
  docker stop bizdock
  docker rm bizdock
  docker run --name=bizdock -d --net=bizdock_network -p $BIZDOCK_PORT:$BIZDOCK_PORT_DEFAULT \
   -v /var/opt \
   -v /opt/mysqldump \
   $CONFIG_VOLUME \
   $MAF_FS \
   -e CONFIGURE_DB_INIT=$CONFIGURE_DB \
   taf/bizdock:11.0.1 --useruid $(id -u $(whoami)) --username $(whoami)
fi

