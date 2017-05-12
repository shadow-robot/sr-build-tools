# Ansible

Ansible roles for installing generic ROS things as well as specific Shadow projects.

Also contains the playbook (vagrant_site.yaml) used for provisioning the Vagrant virtual machines.

## Continous Integration servers 
The extra roles were added to run builds and different checks of the project on the hosted servers.
The main playbook for these tasks is [docker_site.yml](./docker_site.yml).

More details can be found [here](roles/ci/doc/README.md)

## Default development setup

### General

**deploy.sh** implements very basic functionality for development environment setup for simple repositories in the following cases:

  * single repository which depends on official ROS Debian and PIP packages
  * single repository which partially depends on source code repositories which are stored in file repositories.rosintall file
  * multiple repositories which are described in rosintall file in any repository
  
Shell script is able to install Indigo and Kinetic ROS version plus all needed dependencies.

### Flags

The shell script has the following flags:

  * -o or --owner name of the GitHub repository owner (shadow-robot by default)
  * -r or --repo name of the owners repository (sr-interface by default)
  * -w or --workspace path you want to use for the ROS workspace. The directory will be created. (~{current_user}/workspace/{project_name}/base by default)
  * -v or --rosversion ROS version name (indigo by default)
  * -b or --branch repository branch
  * -i or --installfile relative path to rosintall file in repository (default /repository.rosinstall)
  * -l or --githublogin github login for private repositories.
  * -p or --githubpassword github password for private repositories.
  * -t or --tagslist tags for running a specific part of the configuration of the playbook

### Simple repository without repository.rosinstall

Install repository ros/roslint from GitHub into roslint workspace **~{current_user}/workspace/roslint/base** using ROS Indigo.
Tries to read any possible dependencies from repositories.rosinstall and install them into **~{current_user}/workspace/roslint/base_deps**

```bash
bash <(curl -Ls https://raw.githubusercontent.com/shadow-robot/sr-build-tools/master/ansible/deploy.sh) -o ros -r roslint -v indigo
```

### Simple repository with repository.rosinstall

Install repository shadow-robot/build-servers-check from GitHub into build-servers-check workspace **~{current_user}/workspace/build-servers-check/base** using ROS Kinetic.
Tries to read any possible dependencies from repositories.rosinstall and install them into **~{current_user}/workspace/build-servers-check/base_deps**

```bash
bash <(curl -Ls https://raw.githubusercontent.com/shadow-robot/sr-build-tools/master/ansible/deploy.sh) -r "build-servers-check" -b "kinetic-devel" -v kinetic
```

### Multiple repositories from rosinstall file

This script will install all repositories which are described in ros-planning/moveit GitHub repository (branch kinetic-devel) inside file moveit.rosinstall.
Tries to read any possible dependencies from repositories.rosinstall and install them into **~{current_user}/workspace/build-servers-check/base_deps**

```bash
bash <(curl -Ls https://raw.githubusercontent.com/shadow-robot/sr-build-tools/master/ansible/deploy.sh) -o "ros-planning" -r moveit -b "kinetic-devel" -i moveit.rosinstall -v kinetic 
```

To include installation of the mongodb database an extra flag is required

```bash
bash <(curl -Ls https://raw.githubusercontent.com/shadow-robot/sr-build-tools/master/ansible/deploy.sh) -o "ros-planning" -r moveit -b "kinetic-devel" -i moveit.rosinstall -v kinetic -t mongodb
```
