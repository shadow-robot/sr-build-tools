
| Build server  | Status |
|---------------|--------|
| Travis | [![Build Status](https://travis-ci.org/shadow-robot/build-servers-check.svg)](https://travis-ci.org/shadow-robot/build-servers-check) |
| Shippable | [![Build Status](https://api.shippable.com/projects/55ba073fedd7f2c0528ca1a8/badge?branchName=kinetic-devel)](https://app.shippable.com/projects/55ba073fedd7f2c0528ca1a8/builds/latest) |
| Semaphore | [![Build Status](https://semaphoreci.com/api/v1/projects/3d9a5e21-cb5b-4fae-a942-93e6515682cb/571657/shields_badge.svg)](https://semaphoreci.com/shadow-robot/build-servers-check) |
| Circle | [![Circle CI](https://circleci.com/gh/shadow-robot/build-servers-check.svg?style=shield)](https://circleci.com/gh/shadow-robot/build-servers-check) |

Shadow Robot Build Tools
========================

Various tools and utilities created by [Shadow](http://www.shadowrobot.com) to aid in [ROS](http://ros.org) based robot development. There are two main things of interest here.

* [Vagrant Virtual Machines](vagrant) - Quickly bring up virtual machines for Shadow projects or general ROS development. Also includes a set of machines for building ROS Base images for vagrant.
* [Ansible Roles for ROS](ansible) - Roles and playbooks for general ROS setup as well as specific shadow projects.

To setup a new production machine, [see these instructions](Production Checklist.md)

Structure
---------

* [ansible](ansible) - Ansible roles and playbooks. Go there if you want to setup a new machine running Shadow software quickly or automatic build.
* [bin](bin) - Small executables and scripts. Includes older, bash script based ROS installers being replaced by ansible. Scripts for working with ROS and Jenkins. Also a script to sync between github issues and Trello.
* [data](data) - Rosinstall files for Shadow projects.
* [docker](docker) - Docker image files.
