# BizDock - Deployment - Docker Image

Build and run Docker images to have a deployed BizDock application.

## Structure of the repository

* bizdock
    * ```Dockerfile``` : file to build the Docker image of BizDock.
    * ```startup.sh``` : entrypoint of Docker image (manage configuration files, setup files in volumes and launch BizDock)
    * ```update_bashrc.sh``` : add Java path to ```bashrc```
* bizdock_db
    * ```Dockerfile``` : file to build the Docker image of the BizDock database
    * ```startup.sh``` : entrypoint of Docker image (setup files in volumes, start cron and start mysql)
* ```build_images.sh``` : script to build Docker images
* ```run.sh``` : script to run Docker images

## Requirements

To be able to use Docker images, you need to have Docker Engine installed on your host.
Further informations can be found on the [Docker official website](https://docs.docker.com/engine/installation/).

## Create Docker image

To create the Docker image, you need to be in the [deployment-bizdock-image](https://github.com/theAgileFactory/bizdock-docker/tree/master/deployment-bizdock-image) folder and run the shell command :

```sh
./build_images.sh
```

For building BizDock, you need to put into ```bizdock``` folder the packaged ZIP files (```merged-*.zip```) that you can find in the target folders of ```maf-desktop```, ```maf-dbmdl``` and ```dbmdl-framework```.

*For the moment, the maf-desktop is not publicly available, so you cannot use this Docker container !*

## Get the Docker image (NOT AVAILABLE FOR THE MOMENT)

If you don't want to create your own image, you can get it running the command ```docker pull taf/bizdock_mariadb:10.1.12 && docker pull taf/bizdock:11.0.1```.

## Run the Docker container

To run your container, you need to use the ```run.sh``` script.
For informations about this script, you can use the ```-h``` flag.

This script will run two containers : one for the database and one for production environment.

### Usage

You can give different arguments to the ```run.sh``` script :

* ```-P``` : define the port on which you will access BizDock on your host
* ```-d``` : start a basic database container with default options (user: maf, password: maf)
* ```-s``` : define the database schema (name of the database)
* ```-u``` : define the user of the database (default: maf)
* ```-p``` : define the password for the database user (default: maf)
* ```-H``` : define the datase host and port (ex.: HOST:PORT) - In this case, no database container will be launched
* ```-c``` : define a mount point (on your host) where to store configuration files
* ```-m``` : define a mount point (on your host) where the maf-file-system is stored
* ```-i``` : reset and initialize the database
* ```-h``` : print help

#### First usage

The first time you run the script, you need to pass the ```-i```argument to initialize the database.

## Database

[MariaDB](https://mariadb.org/) is the database used by BizDock.
In addition of the official Docker image of MariaDB, we add to our image a cron job to make dumps of the database.

To define a personalized path on your host to store this cron job, the script to process the ```mysqldump``` and the dumps of the database you need to use the flag ```-b```.
You need to run the container once to allow the container to copy the default files in this folder.

By default, the dump is done every day at 2 AM.
If you want to modify it, you simply need to modify the ```crontabFile``` on your host and restart the database container (```docker restart bizdock_db```).

## Configuration files

You can set a folder on your host where to store the configuration files using the ```-c``` flag.
After running bizdock once, you will find in this folder the default configurations files.
Then, you can configure BizDock as you wish.
To enable the modifications, you simply need to restart the container using ```docker restart bizdock``` or using the ```run.sh``` script.

### Note

This is important to write paths with a ```/``` at the end of them to allow the folders creation for the ```maf-file-system```.

## Logs

To get logs of containers, you can run ```docker logs <container-name>```.
You can find further informations on the [official documentation](https://docs.docker.com/engine/reference/commandline/logs/).

It is up to you to configure a tool to manage logs.
