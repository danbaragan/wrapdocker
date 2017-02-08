edwd
====


# General

Tool for orchestatring build, deploy and maintenence tasks on docker.
It is bash written wrapper over docker and docker-compose that also make use of 
ssh, git, envsubst

This tool relies on a certain structure inside the docker build directory/repo
see structure


# Requirements

bash >= 3.2
docker >= 1.10 (for builds)
?? docker-compose >= 1.8

git
ssh


# Installation

Copy or symlink edwd bash script somewhere in your PATH. The tool consists of only one file.
It should be used from the directory the docker build is in.


# Structure

For a docker ochestration one needs:
1. This tool, edwd
2. The build repo/folder
3. The sources repos/folders, or access to them
In addition some build/deploy specific data is needed, data that will not be stored in repos, like environment
variables, files containing secrets, etc

This tool is to be ran from the docker repo of specific projects.
`.env` file (overriddable) will be sourced into his own running environment. This
environment is set at each invocation and expires afterwards.


## machine structure

From the machine abstraction point of view we have:
1. Own machine
2. Host machine 
3. Docker Containers

### Own machine
Is the machine we are running edwd, docker build, git, ssh in order to build docker images or deploy docker environments
from. So this machine also holds environment vars and secrets required for edwd build and edwd deploy

### Host machine
This is the machine used to host docker. Usually a linux box. For those developing straight on linux this can be
configured to be their own machine. ssh will still be used, towards own machine, for consistency.
For those developing under windows or mac this will probably be still their own machine since there are other
abstactions on those systems to delegate commands towards the docker deamon from his own linux machine.
When Host machine is Own machine make `EDW_DEPLOY_HOST` point towards your Own machine.

The edwd build command has nothing to do with the Host machine. It builds images on Own machine and pushes them to docker.hub
All other commands have - they apply to the `EDW_DEPLOY_HOST`

### Docker containers
Theses are configured by the environment that built the images on Own machine AND by the files pushed on the Host
machine by the edwd deploy command (originating still from Own machine).
In other words, some variables are fixed at edwd build time from Own machine environment and others are fixed by
edwd deploy command still from (not persistent otherwise) env/files on Own machine (like secret key that are not to be attached to a docker images, but rather depend on the deployment machine environment).
Usually docker-compose is running in a certain deploy folder on the Host machine. (created by edwd deploy command ran on
Own machine)

# Options

The tool takes command line options followed by a command which can also have options.
Due to the nature of argparse only one letter short options are available.
The option can be mixed in any posix way: -a -b -c 1, -a -b -c1, -abc1, etc.

The tool has a command line help. To display it, run:
`edwd -h`
edwd will use configuration from enviroment (variables starting with `EDW_*`) 
it reads such variables from file .env that should be present in the build/deploy dir.
this can be overriden with -e option.


# Commands

## build

Build docker images required for a deployment.
These images are built based on .env environment, cmd line overrides, docker build files from current folder
and a sources directories (taken from git or from local folders)

For help run:
`edwd build -h`

## deploy
`edwd deploy -h`

## up
## stop
