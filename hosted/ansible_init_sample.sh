#!/usr/bin/env bash

sudo apt-get update
sudo apt-get install python-dev libxml2-dev libxslt-dev python-pip -y
sudo pip install ansible

mkdir -p ~/workspace
cd ~/workspace

git clone https://github.com/shadow-robot/sr-build-tools.git
cd ./sr-build-tools
git checkout F_hosted_build_support

sudo ansible-playbook -v -i "localhost," -c local ./ansible/docker_site.yml --tags "shippable,install,create_workspace,update_dependencies,build,unit_tests" -e "shippable_repo_dir=$SHIPPABLE_REPO_DIR"
