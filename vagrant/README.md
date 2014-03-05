Shadow Vagrant
==============

[Vagrant](http://vagrantup.com) machines to generte Vagrant base images for ROS work and machines for Shadow projects. Uses [Ansible](http://ansible.com) for configuration managment, see ansible directory at root of project the playbooks a set of roles for setting up ros machines, users and workspaces.

## Install and Setup

To get going you need to have the build tools repos and an install of ansible. We have been using a [source install of ansible](http://docs.ansible.com/intro_installation.html#running-from-source) to develop this.

```sh
$ # Setup Ansible
$ mkdir -p ~/opt/ansible
$ cd ~/opt/ansible
$ git clone git://github.com/ansible/ansible.git
$ cd ./ansible
$ source ./hacking/env-setup
$ sudo pip install paramiko PyYAML jinja2 httplib2
$ #
$ # Get the build tools
$ mkdir -p ~/ShadowRobot/
$ git clone git@github.com:shadow-robot/sr-build-tools.git
$ cd git@github.com:shadow-robot/sr-build-tools.git
```

## Building the base image

## Building the hand machine
