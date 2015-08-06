#!/usr/bin/env bash

export toolset_branch=$1
export server_type=$2
export tags_list=$3

export docker_image="andriyp/ubuntu-ros-indigo-build-tools"
export build_tools_folder="$HOME/sr-build-tools"

# Do not install all libraries for circle because we are using docker container directly
if [ "circle" != $server_type ]; then
  sudo apt-get update
  sudo apt-get install python-dev libxml2-dev libxslt-dev python-pip lcov wget git -y
  sudo pip install ansible gcovr
fi

# Check in case of cached file system
if [ -d $build_tools_folder ]; then
  # Cached
  cd $build_tools_folder
  git pull origin "$toolset_branch"
  cd ./ansible
else
  # No caching
  git clone https://github.com/shadow-robot/sr-build-tools.git -b "$toolset_branch" $build_tools_folder
  cd $build_tools_folder/ansible
fi

case $server_type in

"shippable") echo "Shippable server"
  export extra_variables="shippable_repo_dir=$SHIPPABLE_REPO_DIR  shippable_is_pull_request=$PULL_REQUEST codecov_secure=$CODECOV_TOKEN"
  sudo ansible-playbook -v -i "localhost," -c local docker_site.yml --tags "shippable,$tags_list" -e "$extra_variables"
  ;;

"semaphore") echo "Semaphore server"
  mkdir -p ~/workspace/src
  export project_dir_name=$(basename $SEMAPHORE_PROJECT_DIR)
  mv $SEMAPHORE_PROJECT_DIR ~/workspace/src
  export new_project_dir=~/workspace/src/$project_dir_name
  sudo apt-get remove mongodb-* -y
  sudo apt-get remove rabbitmq-* -y
  sudo apt-get remove redis-* -y
  sudo apt-get remove mysql-* -y
  sudo apt-get remove cassandra-* -y
  export extra_variables="semaphore_repo_dir=$new_project_dir  semaphore_is_pull_request=$PULL_REQUEST_NUMBER codecov_secure=$CODECOV_TOKEN"
  sudo ansible-playbook -v -i "localhost," -c local docker_site.yml --tags "semaphore,$tags_list" -e "$extra_variables"
  ;;

"circle") echo "Circle CI server"
  docker pull $docker_image
  export extra_variables="circle_repo_dir=/host$CIRCLE_REPO_DIR  circle_is_pull_request=$CI_PULL_REQUEST circle_test_dir=/host$CI_REPORTS circle_code_coverage_dir=/host$CIRCLE_ARTIFACTS codecov_secure=$CODECOV_TOKEN"
  # TODO Fix Path to sr-build-tools after docker hub image refresh !!!
  docker run -w "/sr-build-tools/ansible" -v /:/host:rw $docker_image  bash -c "git pull && git checkout $toolset_branch && sudo ansible-playbook -v -i \"localhost,\" -c local docker_site.yml --tags \"circle,$tags_list\" -e \"$extra_variables\" "
  ;;

"docker_hub") echo "Docker Hub"
  sudo ansible-playbook -v -i "localhost," -c local docker_site.yml --tags "docker_hub,$tags_list"
  ;;

*) echo "Not supported server type $server_type"
  ;;
esac
