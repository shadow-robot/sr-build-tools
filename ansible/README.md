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
  * -w or --workspace path you want to use for the ROS workspace. The directory will be created. (~/indigo_ws by default)
  * -v or --v ROS version name (indigo by default)
  * -b or --branch repository branch
  * -i or --installfile relative path to rosintall file in repository (default /repository.rosinstall)
  * -l or --githublogin github login for private repositories.
  * -p or --githubpassword github password for private repositories.

### Simple repository without repository.rosinstall

```bash
bash <(curl -Ls https://raw.githubusercontent.com/shadow-robot/sr-build-tools/master/ansible/deploy.sh) -o ros -r roslint -v indigo
```

### Simple repository with repository.rosinstall

```bash
bash <(curl -Ls https://raw.githubusercontent.com/shadow-robot/sr-build-tools/master/ansible/deploy.sh) -r "build-servers-check" -v kinetic
```

### Multiple repositories from rosinstall file

```bash
bash <(curl -Ls https://raw.githubusercontent.com/shadow-robot/sr-build-tools/master/ansible/deploy.sh) -o "ros-planning" -r moveit -b "kinetic-devel" -i moveit.rosinstall -v kinetic 
```
