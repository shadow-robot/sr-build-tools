
| Build server  | Status |
|---------------|--------|
| Travis | [![Build Status](https://travis-ci.org/shadow-robot/build-servers-check.svg)](https://travis-ci.org/shadow-robot/build-servers-check) |
| Circle | [![Circle CI](https://circleci.com/gh/shadow-robot/build-servers-check.svg?style=shield)](https://circleci.com/gh/shadow-robot/build-servers-check) |

Shadow Robot Build Tools
========================

Various tools and utilities created by [Shadow](http://www.shadowrobot.com) to aid in [ROS](http://ros.org) based robot development.

* [Ansible Roles for ROS](ansible) - Roles and playbooks for general ROS setup as well as specific shadow projects.
* [Ansible Roles readme](/ansible/README.md)

To setup a new production machine, [see these instructions](Production Checklist.md)

Structure
---------

* [ansible](ansible) - Ansible roles and playbooks. Go there if you want to setup a new machine running Shadow software quickly or automatic build.
* [bin](bin) - Small executables and scripts. Includes older, bash script based ROS installers being replaced by ansible. Scripts for working with ROS. Also a script to sync between github issues and Trello.
* [docker](docker) - Docker image files.
