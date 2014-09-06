Shadow Vagrant
==============

[Vagrant](http://vagrantup.com) setup to generte Vagrant base images for [ROS](http://ros.org) work and machines for Shadow projects. Uses [Virtual Box](https://www.virtualbox.org/) for virtualisation and uses [Ansible](http://ansible.com) for configuration managment, see ansible directory at root of the project for the playbooks and a set of roles for setting up ROS machines, users and workspaces.

## What you'll find here
Different machines configuration are stored here:

* **hand/** is a stable machine for working with the simulated Shadow Hand
* **dev/** contains the development machines (source install, development environment setup)
** *dev/hand* is a development machine for the Shadow Hand
* **production** contains the machines used for shipping to customers
** *production/hand* is the Hand for customers machine
* **ronex**
* **experimental** contains more advanced machines (different ros versions, different projects, etc...)
* **ros-base** used to build vagrant base images used for the other boxes.

## Install and Setup

To start, [install the latest virtual box](https://www.virtualbox.org/wiki/Linux_Downloads). We have been using the oracle release (not the plain Ubuntu packages) and you will need to install the extension pack. I'd suggest adding their repo to your machine.

Next you need ansible, for trusty:
```sh
apt-get install ansible
```

Older ubuntus and developers may need a [source install of ansible](http://docs.ansible.com/intro_installation.html#running-from-source).

Now grab the build tools:
```sh
git clone git@github.com:shadow-robot/sr-build-tools.git
```

## Start the hand machine

To start a machine cd into it's directory and vagrant up. For the hand:

```sh
$ cd sr-build-tools/vagrant/hand
$ vagrant up
```

## New ROS Vagrant machine from base image

```sh
mkdir ~/rosvm
cd ~/rosvm
vagrant init ros-indigo-desktop-trusty64
# Set vb.gui = true in Vagrantfile
vagrant up
```
