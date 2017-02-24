edwd
====


# General

Tool for orchestatring build, deploy and maintenence tasks on docker.
It is bash written wrapper over docker and docker-compose that also make use of 
ssh, git, envsubst

This tool relies on a certain structure inside the docker build directory/repo
see structure


# Requirements

- bash >= 3.2
- docker >= 1.10 (for builds)
- docker-compose >= 1.8
- git
- ssh


# Installation

Symlink edwd bash script somewhere in your PATH. The tool consists of only one file.
It should be used from within the directory of the docker ochestration repo of a project

# Quick guide
This makes use of concepts presented further down, but could be useful on revisiting this procedure.

## initial use setup

- Have docker, ssh, git, bash on Own machine
- Have docker, docker-compose, other stuff like apache on Host machine
- Have edwd from this repo (one file); symlink it to somewhere in your `$PATH`. I recommend `$HOME/bin/`
- Have docker orchestration repo for the project
- make `EDW_DEPLOY_USER` be able to ssh through public key from your machine to `EDW_DEPLOY_HOST`
- `docker login`

## build, deploy, operations
- Setup .env file based on .env.sample. Make sure to add `EDW_BUILD_subproj_SRC` for any images that need the sources.
- `edwd build`
- make sure any secret env file is populated with right values. See .example files.
- edwd deploy -s (for initial deploy you will probably not want to start the suite right away)
- run any initial setup scripts your occhestrastion repo holds. from yoru own machine, or if in deploy.manifest, from Host machine, as they have been copied by `edwd deploy`
- edwd up
- edwd stop

## quick guide for non edwd users
This is meant for local devs that do not wish to use edwd.
- Have docker, docker-compose, git on own machine
- Have docker orchestration repo for the project
- Have the subprojects src repos
- setup docker-compose.override.yml (see .sample) Use volume to shadow the src files inside the image.
- setup secret env files, setup runtime services uris to some external test services if you do not plan bare init all
the services (`solr` for instance). Make sure you mention those overrides in `docker-compose.override.yml` on
`environment` clause.
- docker-compose up -d


# Structure


## Overview

For a docker ochestration one needs:
1. This tool, edwd; although it can be bypassed altogether if you run some commands manually
2. The orchestation repo/folder
3. Acess to the subprojects sources repos
4. Out of any repo `.env` that is sourced at edwd run time and secret env file that tweaks the runtime of the
   docekr container
5. Own machine, Host machine, built and pushed docker images


## machine structure

From the machine abstraction point of view we have:
1. Own machine
2. Host machine 
3. Docker Containers


### Own machine

Is the machine we are running edwd on; With or w/o using edwd this boils down to docker build, git, ssh, etc in order to build docker images, deploy docker orchestration and environments and interact with docker containers inside the Host machine.
In order for this to work one needs a woking bash on it's own machine.

In a stripped down version of these functionalities, i.e. for development and without `edwd`, `build`, `deploy` and edwd driven interactions, one needs at least `docker`, `docker-compose` and propper settings in `docker-compose.override.yml` (see the sample)


### Host machine

This is the machine used to host docker. Usually a linux box. For those developing straight on linux this can be
configured to be their own machine. ssh will still be used, towards own machine, for consistency, but see stripped down
functionality.
For those developing under windows or mac this will probably be still their own machine since there are other
abstactions on those systems to delegate commands towards the docker deamon in his own linux machine.
When Host machine is Own machine make `EDW_DEPLOY_HOST` point towards `localhost`

The edwd build command has nothing to do with the Host machine. It builds images on Own machine and pushes them to docker.hub
All other commands have - they apply to the `EDW_DEPLOY_USER`@`EDW_DEPLOY_HOST`:`EDW_DEPLOY_DIR`


### Docker containers

These are configured by the environment (`.env` file holds such vars) that built the images on Own machine through `--build-arg` flag. This changes are "set in stone" in the image built.
These are also configured at runtime (each container start) by the `EDW_RUN_*` vars *through* the docker-compose mechanism. That is, docker-compose.yml/override will be made aware of this vars and *has to explicitly overwrite* variables from `env_file` entry with `environment` variables declared in yml. By mere presence of the `EDW_RUN_` vars inthe environment ot the docker-compose these runtime vars will not be passed to the container environment.
In other words one must place modified `EDW_RUN_` vars both in `.env` file and mention them in
docker-compose.yml/override. This might seem complicated but note that the proper way to alter `EDW_RUN_` variables is
to change them in files mentioned in `env_file` and deploy those files on the specific Host machine. The two step env
overwrite is meant for development container customization on Own machine.

The deploy mechanism copies necessary `env_file` to host machine, the `.env` file used on own machine at deploy time
and docker-compose.yml that will make use of all these.
machine by the edwd deploy command (originating still from Own machine).


## The orchestation repo

This should have a certain structure.
While your current working directory is the ochestration dir one can perform `build`, `deploy` and other maintenance and
interaction commands, like `up`, `stop`, etc.
Everything uder this section will assume orchestration dir as cwd.
This should contain
- docker.manifest
- docker-compose.yml
- build dir
- deploy dir

### .env
This file contains variables that edwd will export for all it's functions and subshells to access.
This file will also endup on the host machine when doing deploy.
It is necessary that this file does *not contain any comments*. Although comments allow it to be sourced, it makes
inline expansion of the env vars more difficult. (we depend on env `xargs < .env` <Some command that depends on certain env>)

The env vars hava a certain namespace:

#### build variables
- `EDW_BUILD_` - variables used at image `build` time.
- `EDW_BUILD_PROJECT` - is prepended to docker image being built. This prevents the random cwd name to be added to the image name by docker-compose.
Note that because of v3 compatibility docker-compose only points to `image` not `build` directives and it is not used during image build (plain docker is used)
- `EDW_BUILD_DOCKERHUB` - the docker.hub namespace where images are being pushed to and pulled from. You should be 
`docker login`
- `EDW_BUILD_<lowercase_subproject_name>_` vars are automatically injected in the docker build environment and should be
consumed acordingly
- `EDW_BUILD_<lowercase_subproject_name>_SRC` special var. This one, if present, specifies the additional source repo to
be cloned under a temporary build dir.
The syntax is `repoUrl,branch_or_tag=something`. If the argument after `,` is missing branch master is used.
The clone is shallow and thus light on disk/network.
- `EDW_BUILD_VER` will tag both docker images built and subprojects git repos. It will also be used by docker-compose to use a certain image tag when bringing up the suite.

#### deploy variables
- `EDW_DEPLOY_` - vars used for comunication from Own machine to Host machine
i.e. `$EDW_DEPLOY_USER@$EDW_DEPLOY_HOST:$EDW_DEPLOY_DIR`

#### run variables
These end up in the container environment *if docker-compose passes them to the container*
The `.env` RUN variables will be given as environment to the docker-compose. docker-compose use some of these
variables into deciding how to start a suite (see `EDW_BUILD_VER`) He will also pass env to containers in the following
manner: load env variables from the files specified in `env_file` (RUN variables should be specified there) and also may
choose to explicitly overwrite some of them from its current running environment through use of `environment` clause.
Note that the way one should change the container running environment is through files loaded by `env_file` clause.
The two step overwrite (.env -> ruuning env of docker-compose -> explicit mention in environment clause -> docker
container environment) is meant to be used on Own machine for development changing *only* docker-compose.override.yml,
not docker-compose.yml (see docker-compose.override.yml.sample)

Each docker ochestration repo should document its own specific RUN env vars.


### docker build files

These are under build dir.
Each subproject that needs to have an image built has a *lowercase* dir there. That dir should *not contain underscores
_* and should also be identical to the services under docker-compose.yml. The latter is a recommendation. The former is
required in some patern matching done by edwd, but it can be extended should the need arise.

Each subproject that needs to have an image built dir should contain a `Dockerfile` and the build specific files refered
by the Dockerfile.


### docker-compose files; environment files; deploy.manifest

The deploy.manifest file will specify which file paths should be copied from Own machine docekr orchestration repo down to
Host machine.
Usually these are the `docker-compose.yml` and files loaded through `env_file` clause.
i.e.
```
docker-compose.yml
deploy/common.env
deploy/web/docker.env
deploy/solr/docker.env
deploy/secret.env
www_static/
```

`edwd deploy` will create `EDW_DEPLOY_DIR` if it does not exist. Make sure your are pointing to a dir the
`EDW_DEPLOY_USER` has write access to.
All the paths in `deploy.manifest` should be relative to the orchestration repo and will be create relative to
`EDW_DEPLOY_DIR`
It will also create the directory structure for files paths in `deploy.manifest`.
If a directory is mentioned by its own it will be created on Host machine

#### special tag files

`current_tag`, `old_tag` and `old_old_tag` are fiels that `edwd deploy` will, in time, create on the Host
machine, under `EDW_DEPLOY_DIR`. These are used to know wich version is deployed and to do reverts if needed.

#### special `lockdow_deploy`

if `lockdown_deploy` special file is found in `EDW_DEPLOY_DIR` the `edwd deploy` will not deploy there unless `-f` option is given.
`edwd lockdown message stating the reason` will create such a file and place the reason in it.


# Options

The tool takes command line options followed by a command which can also have options.
Due to the nature of argparse only one letter short options are available.
The option can be mixed in any posix way: -a -b -c 1, -a -b -c1, -abc1, etc.

The tool has a command line help. To display it, run:
`edwd -h`
edwd will use configuration from enviroment (variables starting with `EDW_*`) 
it reads such variables from file .env that should be present in the build/deploy dir.
this can be overriden with `-e <some other file>` option.


# Commands

## build

Build docker images required for a deployment.
These images are built based on .env environment and docker build files from each `build/<subproject_name>` dir

One can safely run this command even only to be present with the build context, env vars, command line option
alterations, etc.

`build` will create docker images based on `EDW_BUILD_` vars and contents of build directory. See above in the
orchestration repo how these are used.
Short story. each `build/subporject/Dockerfile` is built in an image named
`$EDW_BUILD_DOCKERHUB/$EDW_BUILD_PROJECT_subproject:$EDW_BUILD_VER`
The `$EDW_BUILD_subproject_SRC` var, if present, will point to an `gitRepoUrl,branch_or_tag=name` which will be used
during Dockerfile build.
build time files present will be used if referred to by the Dockerfile.
The `$EDW_BUILD_subproject_*` vars are passed as ARG, `--build-arg` to docker build and should be consumed by the
Dockerfile
Images are pushed to docker.hub; one should be logged in. Also git tag named by `$EDW_BUILD_VER` will be pushed to
github for subporjects that popinted to a source repo by `EDW_BUILD_subproject_SRC` 
`-n` option will prevent this.
The `-p subproj1,subporj2` will specify which projects to build instead of all build/subproject with a Dockerfile.

For help run: `edwd build -h`


## deploy

Deploy docker images `$EDW_BUILD_DOCKERHUB/$EDW_BUILD_PROJECT_subproject:$EDW_BUILD_VER` to
`$EDW_DEPLOY_USER@$EDW_DEPLOY_HOST:$EDW_DEPLOY_DIR` and copy files / create dirs mentioned in `deploy.manifest`
`-p subproj1,subproj2` overrides which projectes will get their images pulled. The fiels in `deploy.manifest` are all
copied.
Does not deploy if `lockdown_deploy` present on Host machine, `$EDW_DEPLOY_DIR`. `-f` overrides this and also deletes the
file.
Does not deploy on if `$EDW_DEPLOPY_HOST` is `localhost`. `-o` option overrides this.

`-s` option prevents restart of the suite. Use this on initial deployments if you need to make adjustments before inital
start.

For help run: `edwd deploy -h`


## up

`edwd up [f]` will start the suite on the `$EDW_DEPLOY_HOST` from dir `$EDW_DEPLOY_DIR`. By default in background.


## stop

`edwd stop` will stop the suite from the `$EDW_DEPLOY_HOST:$EDW_DEPLOY_DIR`

## lockdown

`edwd lockdown` - create `lockdown_deploy` on Host machine
