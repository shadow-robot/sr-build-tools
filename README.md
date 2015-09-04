Shadow Robot Build Tools
========================

Various tools and utilities created by [Shadow](http://www.shadowrobot.com) to aid in [ROS](http://ros.org) based robot development. There are two main things of interest here.

* [Vagrant Virtual Machines](vagrant) - Quickly bring up virtual machines for Shadow projects or general ROS development. Also includes a set of machines for building ROS Base images for vagrant.
* [Ansible Roles for ROS](ansible) - Roles and playbooks for general ROS setup as well as specific shadow projects.

Structure
---------

* [ansible](ansible/README.md) - Ansible roles and playbooks. Go there if you want to setup a new machine running Shadow software quickly.
* [bin](bin/README.md) - Small executables and scripts. Includes older, bash script based ROS installers being replaced by ansible. Scripts for working with ROS and Jenkins. Also a script to sync between github issues and Trello.
* [config](config/README.md) - Config files (**not** ansible or vagrant). Just an example of the trello sync config for now.
* [data](data/README.md) - Rosinstall files for Shadow projects.
* [docker](docker/README.md) - Docker image files.
* [vagrant](vagrant/README.md) - Vagrant virtual machines.
