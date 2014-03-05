Shadow Vagrant
==============

[Vagrant](http://vagrantup.com) setup to generte Vagrant base images for [ROS](http://ros.org) work and machines for Shadow projects. Uses [Virtual Box](https://www.virtualbox.org/) for virtualisation and uses [Ansible](http://ansible.com) for configuration managment, see ansible directory at root of the project for the playbooks and a set of roles for setting up ROS machines, users and workspaces.

## Install and Setup

To start, [install the latest virtual box](https://www.virtualbox.org/wiki/Linux_Downloads). We have been using the oracle release (not the plain Ubuntu packages) and you will need to install the extension pack. I'd suggest adding their repo to your machine.

Then you need to have the build tools repos and an install of ansible. We have been using a [source install of ansible](http://docs.ansible.com/intro_installation.html#running-from-source) to develop this. e.g.

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

The main machines use a custom made ROS base image that takes the basic ubuntu base, adds the desktop system and a full ROS desktop install. To build:
```sh
$ cd sr-build-tools/vagrant/ros-hydro-desktop-precise64/
$ vagrant up
```
Now go make tea, this takes a while... Building this base image now saves us lots of time in future when building all the other machines.

Once that builds restart the machine to bring the newly installed GUI up:

```sh
$ vagrant halt
$ vagrant up
```

You may get an error about failing to mount folders, this because the guest additions will need updating. You should do this anyway even without the error.

* Log into the machine as the vagrant user (password vagrant) 
* Select Devices -> Install Guest Additions CD Image on the virtual box window.
* Click yes for the autorun prompt.

TODO - Create box and install it.

## Start the hand machine

```sh
$ cd sr-build-tools/vagrant/hand-hydro-precise64
$ vagrant up
```
