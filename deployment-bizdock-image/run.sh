#!/bin/sh

HELP=$'Available options: \n\t-P - main Bizdock port\n\t-n - bizdock public URL\n\t-d - start a basic database container with defaults options\n\t-s - database schema (name of the database)\n\t-u - database user\n\t-p - database password\n\t-H - database host and port in case the db is not set up as a docker instance (ex. HOST:PORT)\n\t-m - optional mount of the maf-file-system volume on the host\n\t-h - help\n\t-c - initialize databse'

DB_NAME_DEFAULT='maf'
DB_USER_DEFAULT='maf'
DB_USER_PASSWD_DEFAULT='maf'
DB_NAME=
DB_USER=
DB_USER_PASSWD=
DB_HOST=""
MOUNT_VOLUME=
URL='localPORT'
BIZDOCK_PORT=8000
BIZDOCK_PORT_DEFAULT=8000
DISTANT_DB=false
CONFIGURE_DB=false

if [ $? != 0 ] # There was an error parsing the options
then
  echo "Unkown option $1"
  echo "$HELP"
  exit 1 
fi

# Process the arguments
while getopts ":P:n:ds:u:p:H:m:hc" option
do
  case $option in
    P)
      BIZDOCK_PORT="$OPTARG"
      ;;
    n)
      URL="$OPTARG"
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
      MOUNT_VOLUME="$OPTARG"
      MOUNT_VOLUME="-v $MOUNT_VOLUME:/opt/start-config/"
      ;;
    h)
      echo "$HELP"
      exit 0
      ;;
    c)
      CONFIGURE_DB=true
      echo "$CONFIGURE_DB"
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
if [ -z "$MOUNT_VOLUME" ]; then
  MOUNT_VOLUME="-v /opt/start-config/"
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
    docker run --name=bizdock_db -d --net=bizdock_network $DB_HOST -v bizdock_database:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE="$DB_NAME" -e MYSQL_USER="$DB_USER" -e MYSQL_PASSWORD="$DB_USER_PASSWD" theagilefactory/bizdock_mariadb:10.1.12 
  fi
else
  echo "/!\\ Connection to a distant DB through properties files /!\\"
fi

#Run Bizdock
echo "---- RUNNING BIZDOCK ----"
INSTANCE_TEST=$(docker ps -a | grep -e "bizdock$")
if [ $? -eq 1 ]; then
  docker run --name=bizdock --rm -ti --net=bizdock_network -p $BIZDOCK_PORT:$BIZDOCK_PORT_DEFAULT \
   -v /var/opt \
   -v bizdock_backups:/var/opt/backups \
   -v /opt/mysqldump \
   $MOUNT_VOLUME \
   -e PUBLIC_URL=$URL \
   -e CONFIGURE_DB_INIT=$CONFIGURE_DB \
   theagilefactory/bizdock:11.0.1
else
  docker stop bizdock
  docker rm bizdock
  docker run --name=bizdock --rm -ti --net=bizdock_network -p $BIZDOCK_PORT:$BIZDOCK_PORT_DEFAULT \
   -v /var/opt \
   -v bizdock_backups:/var/opt/backups \
   -v /opt/mysqldump \
   $MOUNT_VOLUME \
   -e PUBLIC_URL=$URL \
   -e CONFIGURE_DB_INIT=$CONFIGURE_DB \
   theagilefactory/bizdock:11.0.1
fi
