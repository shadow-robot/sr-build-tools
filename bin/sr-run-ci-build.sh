#!/usr/bin/env bash

export toolset_branch=$1
export server_type=$2
export tags_list=$3

sudo apt-get update
sudo apt-get install python-dev libxml2-dev libxslt-dev python-pip lcov wget git -y
sudo pip install ansible gcovr

# Check in case of cached file system
if [ -d "./sr-build-tools" ]; then
  # Cached
  cd ./sr-build-tools
  git pull origin "$toolset_branch"
  cd ./ansible
else
  # No caching
  git clone https://github.com/shadow-robot/sr-build-tools.git -b "$toolset_branch" sr-build-tools
  cd ./sr-build-tools/ansible
fi

if [ "shippable" == $server_type ]; then
    export extra_variables="shippable_repo_dir=$SHIPPABLE_REPO_DIR  shippable_is_pull_request=$PULL_REQUEST codecov_secure=$CODECOV_TOKEN"
    sudo ansible-playbook -v -i "localhost," -c local docker_site.yml --tags "shippable,$tags_list" -e "$extra_variables"
else
   if [ "docker_hub" == $server_type ]; then
        sudo ansible-playbook -v -i "localhost," -c local docker_site.yml --tags "docker_hub,$tags_list"
    else
        echo Not supported server type $server_type
    fi
fi
