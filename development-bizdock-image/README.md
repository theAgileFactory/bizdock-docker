# BizDock - Development - Docker Image

Build and run a Docker image to have a development environment of BizDock.

## Structure of the repository

* ```use```
    * ```bizdockctl.sh``` : a command line script (is not inserted into the image) to control the creation of the docker containers
* ```bizdockdb-dbmdl-framework.properties``` : default properties of the dbmdl framework
* ```bizdockdb-maf-dbmdl.properties``` : default properties of the maf dbmdl
* ```bizdock-packaging.properties``` : default properties of the bizdock packaging component
* ```build.sh``` : script to build the application inside the docker image (interactive mode)
* ```db.sh``` : script to update (and initialize) the database (interactive mode)
* ```Dockerfile``` : file to build the Docker image
* ```install_maven.sh``` : script used to install maven into the container
* ```install_play.sh``` : script to install the [Java Play Framework](https://www.playframework.com/) into the container
* ```interactive.sh``` : script to setup a user into the container
* ```startup.sh``` : entrypoint of the Docker image that copy persistent file to Docker volumes and clone BizDock repositories from Github.
* ```update_bashrc.sh``` : script used to setup ```.bashrc``` for the current user with paths for Java and Activator.

## Requirements

To be able to use Docker images, you need to have Docker Engine installed on your host.
Further informations can be found on the [Docker official website](https://docs.docker.com/engine/installation/).

## Create Docker image

To create the Docker image, you need to be in the [development-bizdock-image](https://github.com/theAgileFactory/bizdock-docker/tree/master/development-bizdock-image) and run the shell command :

```sh
docker build -t taf/dev-app .
```

## Get the Docker image (NOT AVAILABLE FOR THE MOMENT)

If you don't want to create your own image, you can get it running the command ```docker pull taf/dev-app```.

## Run the Docker containers

To run your container, you need to use the ```use/bizdockctl.sh``` script.
For informations about this script, you can use the ```-h``` flag.

This script will run two containers : one for the database and one for the development and building environment.

### Usage

The script needs at least one argument which is ```-w```. Indeed, you need to give the path to an existing folder on your host where the container will store the git folders and the build scripts.

The second argument needed is ```-i``` to run the container interactively (if this is your first usage, please read first the ```First usage``` section below).

Once your Docker container is launched and you have access to the shell, you can execute ```./build.sh``` to compile the whole application (it could take long to be done).

When you do some modifications only in the ```Model``` for example, you can run ```build.sh``` with the flag ```-m``` to compile only what is necessary.
You can find further options with the ```-h``` flag.

Once it is finished, you can run the ```db.sh``` script to update your database. If you want to reset your database, you can use the ```-r``` argument.

When everything is built, you simply need to go into ```maf-desktop-app``` directory and run ```activator``` to launch the [Java Play Framework](https://www.playframework.com/). When it is launched, you simply need to execute ```run 9000``` to run BizDock. 

Bizdock will be available on ```localhost:8080``` by default (use ```-p``` when launching ```bizdockctl.sh``` to use another port).

Then, you can import the folders into an IDE like [eclipse](https://www.eclipse.org/) to develop on your host.
By default the projects built using ```buid.sh``` are eclispe compatible.

#### First usage

The first time you run the script, you need to pass the ```-c```argument to clone the git repositories into your workspace (path given to ```-w``` option) and to perform a complete build.

WARNING: this may be quite long depending on the speed of your internet connection.
Be patient !
