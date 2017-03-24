#!/usr/bin/env bash

set -e # fail on errors
#set -x # echo commands run

export toolset_branch=$1
export server_type=$2
export tags_list=$3


export ubuntu_version=${ubuntu_version_name:-"trusty"}
export ros_release=${ros_release_name:-"indigo"}
export docker_image=${docker_image_name:-"shadowrobot/build-tools:$ubuntu_version-$ros_release"}

export docker_user=${docker_user_name:-"user"}
export docker_user_home=${docker_user_home_dir:-"/home/user"}

# Do not install all libraries for docker container CI servers
if  [ "circle" != $server_type ] && [ "semaphore_docker" != $server_type ] && [ "local" != $server_type ] && [ "travis" != $server_type ]; then

  export build_tools_folder="$HOME/sr-build-tools"

  sudo apt-get update
  sudo apt-get install -y python-dev libxml2-dev libxslt-dev python-pip lcov wget git libssl-dev libffi-dev libyaml-dev
  sudo pip install paramiko markupsafe PyYAML Jinja2 httplib2 six ansible
  sudo pip install --upgrade setuptools gcovr

  git config --global user.email "build.tools@example.com"
  git config --global user.name "Build Tools"

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
fi

export extra_variables="codecov_secure=$CODECOV_TOKEN github_login=$GITHUB_LOGIN github_password=$GITHUB_PASSWORD ros_release=$ros_release ubuntu_version_name=$ubuntu_version "

case $server_type in

"travis") echo "Travis CI server"
  sudo docker pull $docker_image
  export extra_variables="$extra_variables travis_repo_dir=/host$TRAVIS_BUILD_DIR  travis_is_pull_request=$TRAVIS_PULL_REQUEST"
  sudo docker run -w "$docker_user_home/sr-build-tools/ansible" -v $TRAVIS_BUILD_DIR:/host$TRAVIS_BUILD_DIR $docker_image  bash -c "git pull && git checkout $toolset_branch && sudo PYTHONUNBUFFERED=1 ansible-playbook -v -i \"localhost,\" -c local docker_site.yml --tags \"travis,$tags_list\" -e \"$extra_variables\" "
  ;;

"shippable") echo "Shippable server"
  export extra_variables="$extra_variables shippable_repo_dir=$SHIPPABLE_BUILD_DIR  shippable_is_pull_request=$PULL_REQUEST"
  sudo PYTHONUNBUFFERED=1 ansible-playbook -v -i "localhost," -c local docker_site.yml --tags "shippable,$tags_list" -e "$extra_variables"
  ;;

"semaphore") echo "Semaphore server"
  mkdir -p ~/workspace/src
  sudo apt-get remove mongodb-* -y
  sudo apt-get remove rabbitmq-* -y
  sudo apt-get remove redis-* -y
  sudo apt-get remove mysql-* -y
  sudo apt-get remove cassandra-* -y
  export extra_variables="$extra_variables semaphore_repo_dir=$SEMAPHORE_PROJECT_DIR  semaphore_is_pull_request=$PULL_REQUEST_NUMBER"
  sudo PYTHONUNBUFFERED=1 ansible-playbook -v -i "localhost," -c local docker_site.yml --tags "semaphore,$tags_list" -e "$extra_variables"
  ;;

"semaphore_docker") echo "Semaphore server with Docker support"

  sudo docker pull $docker_image
  export extra_variables="$extra_variables semaphore_repo_dir=/host$SEMAPHORE_PROJECT_DIR semaphore_is_pull_request=$PULL_REQUEST_NUMBER"
  sudo docker run -w "$docker_user_home/sr-build-tools/ansible" -v /:/host:rw $docker_image  bash -c "git pull && git checkout $toolset_branch && sudo PYTHONUNBUFFERED=1 ansible-playbook -v -i \"localhost,\" -c local docker_site.yml --tags \"semaphore,$tags_list\" -e \"$extra_variables\" "
  ;;

"circle") echo "Circle CI server"
  export CIRCLE_REPO_DIR=$HOME/$CIRCLE_PROJECT_REPONAME
  sudo docker pull $docker_image
  export extra_variables="$extra_variables circle_repo_dir=/host$CIRCLE_REPO_DIR  circle_is_pull_request=$CI_PULL_REQUEST circle_test_dir=/host$CI_REPORTS circle_code_coverage_dir=/host$CIRCLE_ARTIFACTS"
  sudo docker run -w "$docker_user_home/sr-build-tools/ansible" -v $CIRCLE_REPO_DIR:/host$CIRCLE_REPO_DIR -v $CI_REPORTS:/host$CI_REPORTS:rw -v $CIRCLE_ARTIFACTS:/host$CIRCLE_ARTIFACTS:rw $docker_image  bash -c "git pull && git checkout $toolset_branch && sudo PYTHONUNBUFFERED=1 ansible-playbook -v -i \"localhost,\" -c local docker_site.yml --tags \"circle,$tags_list\" -e \"$extra_variables\" "
  ;;

"docker_hub") echo "Docker Hub"
  PYTHONUNBUFFERED=1 ansible-playbook -vvv -i "localhost," -c local docker_site.yml --tags "docker_hub,$tags_list" -e "ros_release=$ros_release ubuntu_version_name=$ubuntu_version"
  ;;

"local") echo "Local run"
  export local_repo_dir=$4

  if [ -z "$unit_tests_result_dir" ]
  then
    export unit_tests_dir="$docker_user_home/workspace/test_results"
  else
    export unit_tests_dir="/host/"$unit_tests_result_dir
  fi
  if [ -z "$coverage_tests_result_dir" ]
  then
    export coverage_tests_dir="$docker_user_home/workspace/coverage_results"
  else
    export coverage_tests_dir="/host/"$coverage_tests_result_dir
  fi
  if [ -z "$benchmarking_result_dir" ]
  then
    export benchmarking_dir="$docker_user_home/workspace/benchmarking_results"
  else
    export benchmarking_dir="/host/"$benchmarking_result_dir
  fi
  docker pull $docker_image

  # Remove untagged Docker images which do not have containers associated with them
  export untagged_images_list="$(sudo docker images -q --filter 'dangling=true')"
  for untagged_image_name in $untagged_images_list; do
    export images_used_by_containers="$(sudo docker ps -a | tail -n +2 | tr -s ' ' | cut -d' ' -f2 | paste -d' ' -s)"
    if [[ $images_used_by_containers != *"$untagged_image_name"* ]]; then
      echo "Removing unused and untagged Docker image $untagged_image_name"
      sudo docker rmi $untagged_image_name
    fi
  done

  export extra_variables="$extra_variables local_repo_dir=/host$local_repo_dir local_test_dir=$unit_tests_dir local_code_coverage_dir=$coverage_tests_dir"
  export extra_variables="$extra_variables local_benchmarking_dir=$benchmarking_dir"
  docker run -w "$docker_user_home/sr-build-tools/ansible" -e LOCAL_USER_ID=$(id -u) $docker_flags --rm -v $HOME:/host:rw $docker_image  bash -c "git pull && git checkout $toolset_branch && git pull && PYTHONUNBUFFERED=1 ansible-playbook -v -i \"localhost,\" -c local docker_site.yml --tags \"local,$tags_list\" -e \"$extra_variables\" "
  ;;

*) echo "Not supported server type $server_type"
  ;;
esac
