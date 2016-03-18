# BizDock - Deployment - Docker Image

Build and run Docker images to have a deployed BizDock application.

## Structure of the repository

* bizdock
    * ```Dockerfile``` : file to build the Docker image of BizDock.
    * ```startup.sh``` : entrypoint of Docker image (manage configuration files, setup files in volumes and launch BizDock)
    * ```update_bashrc.sh``` : add Java path to ```bashrc```
* bizdockdb
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

For building BizDock, you need to put into ```bizdock``` folder the packaged ZIP files (```merged-*.zip```). 
To get these packages you need to use the development image to launch a "builder" container.
You simply need to run the command ```use/bizdockctl.sh -w /a/workspace -c``` in the [development-bizdock-image](https://github.com/theAgileFactory/bizdock-docker/tree/master/development-bizdock-image) folder.
This command will clone the git repositories and build the merged files.
You will find them in ```/a/workspace/deploy/```.

Then, you will copy these files into [bizdock](https://github.com/theAgileFactory/bizdock-docker/tree/master/deployment-bizdock-image/bizdock) folder.


## Get the Docker image (NOT AVAILABLE FOR THE MOMENT)

If you don't want to create your own image, you can get it running the command ```docker pull taf/bizdock_mariadb:10.1.12 && docker pull taf/bizdock:12.0.1```.

## Run the Docker container

To run your container, you need to use the ```run.sh``` script.
For informations about this script, you can use the ```-h``` flag.

This script will run two containers : one for the database and one for the production environment.

### Usage

You can give different arguments to the ```run.sh``` script :

* ```-P``` : define the port on which you will access BizDock on your host (be careful to modify the configuration files as explained in the [development folder](https://github.com/theAgileFactory/bizdock-docker/blob/master/development-bizdock-image/README.md)
* ```-d``` : start a basic database container with default options (user: maf, password: maf)
* ```-s``` : define the database schema (name of the database)
* ```-u``` : define the user of the database (default: maf)
* ```-p``` : define the password for the database user (default: maf)
* ```-r``` : define the password for the database user root
* ```-b``` : define a mount point (on your host) where to store cron job for database dumps
* ```-H``` : define the database host and port (ex.: HOST:PORT) - In this case, no database container will be launched
* ```-c``` : define a mount point (on your host) where to store configuration files
* ```-m``` : define a mount point (on your host) where the maf-file-system is stored
* ```-i``` : reset and initialize the database
* ```-h``` : print help

#### First usage

The first time you run the script, you need to pass the ```-i```argument to initialize the database.

## Database

[MariaDB](https://mariadb.org/) is the database used by BizDock.
In addition of the official Docker image of MariaDB, we add to our image a cron job to make dumps of the database.

By default, the dump is done every day at 2 AM.
If you want to modify it, you simply need to modify the ```crontabFile``` on your host and restart the database container (```docker restart bizdockdb```).
The file is located on the path you chose for parameter ```-b```.

## Configuration files

You can set a folder on your host where to store the configuration files using the ```-c``` flag.
After running bizdock once, you will find in this folder the default configurations files.
Then, you can configure BizDock as you wish.
To enable the modifications, you simply need to restart the container using ```docker restart bizdock``` or using the ```run.sh``` script.

### Note

This is important to write paths with a ```/``` at the end of them to allow the folders creation for the ```maf-file-system```.

This is also important to keep consistency between arguments you give to the ```run.sh``` script and the configuration files (ports, user of the database,...).

## Logs

To get logs of containers, you can run ```docker logs <container-name>```.
You can find further informations on the [official documentation](https://docs.docker.com/engine/reference/commandline/logs/).

It is up to you to configure a tool to manage logs.
