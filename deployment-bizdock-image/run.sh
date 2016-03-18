#!/bin/sh

HELP=$'Available options: \n\t-P - main Bizdock port\n\t-d - start a basic database container with defaults options\n\t-s - database schema (name of the database)\n\t-u - database user\n\t-p - database password\n\t-b - Path to store db backup\n\t-H - database host and port in case the db is not set up as a docker instance (ex. HOST:PORT)\n\t-c - mount point for configuration files\n\t-m - optional mount of the maf-file-system volume on the host\n\t-b - optional mount of the db dump script\n\t-h - help\n\t-i - initialize database' 

DB_NAME_DEFAULT='maf'
DB_USER_DEFAULT='maf'
DB_USER_PASSWD_DEFAULT='maf'
DB_NAME=
DB_USER=
DB_USER_PASSWD=
DB_HOST=""
CONFIG_VOLUME=
DB_SCRIPTS=
BIZDOCK_PORT=8080
BIZDOCK_PORT_DEFAULT=8080
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
      DB_SCRIPTS="$OPTARG"
      if [ ! -d "$DB_SCRIPTS" ]; then
        echo ">> $DB_SCRIPTS does not exist. Please create it."
        exit 1
      fi
      DB_SCRIPTS="${DB_SCRIPTS}:"
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
      ;;
    c)
      CONFIG_VOLUME="$OPTARG"
      if [ ! -d "$CONFIG_VOLUME" ]; then
        echo ">> $CONFIG_VOLUME does not exist. Please create it."
        exit 1
      fi
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
  CONFIG_VOLUME="/opt/start-config/"
fi


#Create network
NETWORK_TEST=$(docker network ls | grep bizdock_network)
if [ $? -eq 1 ]; then
  echo "---- NETWORK CREATION ----"
  docker network create bizdock_network
fi

#Run Bizdock Database
if [ "$DISTANT_DB" = "false" ]; then
  docker volume create --name=bizdock_prod_database

  INSTANCE_TEST=$(docker ps | grep -e "bizdockdb$")
  if [ $? -eq 1 ]; then
    INSTANCE_TEST=$(docker ps -a | grep -e "bizdockdb")
    if [ $? -eq 0 ]; then
      docker rm bizdockdb
    fi
    echo "---- RUNNING DATABASE CONTAINER ----"
    echo ">> By default, the database dump is done every day at 2 am."
    if [ ! -z "$MAF_FS" ]; then
      OUTPUT="${MAF_FS}/outputs:"
    else
      OUTPUT=
    fi
    docker run --name=bizdockdb -d --net=bizdock_network $DB_HOST \
      -v bizdock_prod_database:/var/lib/mysql/ \
      -v ${OUTPUT}/var/opt/db/dumps/ \
      -v $DB_SCRIPTS/var/opt/db/cron/ \
      -e MYSQL_ROOT_PASSWORD=root \
      -e MYSQL_DATABASE="$DB_NAME" \
      -e MYSQL_USER="$DB_USER" \
      -e MYSQL_PASSWORD="$DB_USER_PASSWD" \
      -e MYSQL_DATABASE="$DB_NAME" \
      taf/bizdock_mariadb:10.1.12 --useruid $(id -u $(whoami)) --username $(whoami)

    #wait 10 seconds to give time to DB to start correctly before bizdock
    echo ">> Wait 10 seconds to give time to database container to initialize"
    sleep 10

    #test if db container is up
    if [ -z "$(docker ps | grep bizdockdb$)" ]; then
      echo "/!\\ Database container is not up. BizDock will not start /!\\"
      exit 1
    fi
  else
    echo ">> The database container is already running. If this is not the case, please remove it with the command 'docker rm bizdockdb'"
  fi

  IS_TABLE=$(docker exec -it bizdockdb mysql -h localhost -P 3306 -u "$DB_USER" -p"$DB_USER_PASSWD" -D "$DB_NAME" -e 'show tables;')
  if [ -z "$IS_TABLE" ]; then
    CONFIGURE_DB=true
  fi

else
  echo "/!\\ Connection to a distant DB through properties files /!\\"
fi

#Run Bizdock
echo "---- RUNNING BIZDOCK ----"
INSTANCE_TEST=$(docker ps -a | grep -e "bizdock$")
if [ $? -ne 1 ]; then
  docker stop bizdock
  docker rm bizdock
fi

if [ ! -z "${MAF_FS}" ]; then
  MAF_FS="${MAF_FS}:"
fi
docker run --name=bizdock -d --net=bizdock_network -p $BIZDOCK_PORT:$BIZDOCK_PORT_DEFAULT \
  -v /var/opt \
  -v ${CONFIG_VOLUME}/opt/start-config/ \
  -v ${MAF_FS}/opt/artifacts/maf-file-system/ \
  -e CONFIGURE_DB_INIT=$CONFIGURE_DB \
  taf/bizdock:12.0.1 --useruid $(id -u $(whoami)) --username $(whoami) --port $BIZDOCK_PORT_DEFAULT

