#!/usr/bin/env bash

sudo apt-get install python-pip -y
sudo pip install ansible

mkdir -p ~/workspace
cd ~/workspace

git clone https://github.com/shadow-robot/sr-build-tools.git
cd ./sr-build-tools
git checkout F_hosted_build_support

sudo ansible-playbook -i "localhost," -c local ~/workspace/sr-build-tools/ansible/docker_site.yml --tags "ros_install,ros_workspace"


