#!/usr/bin/env bash

export ros_workspace=$1
export dependencies_file=$2
export github_user=${3:-github_user_not_provided}
export github_password=${4:-github_password_not_provided}

cd $ros_workspace/src

export rosintall_filename=$(basename "$dependencies_file")
export current_repo_count=$(find . -type f -name $rosintall_filename | wc -l)
export previous_repo_count=0
export loops_count=10

while [ $current_repo_count -ne $previous_repo_count ]; do
  find . -type f -name $rosintall_filename -exec wstool merge -y {} \;
  sed -i "s/{{github_login}}/$github_user/g; s/{{github_password}}/$github_password/g" .rosinstall
  wstool update --delete-changed-uris

  export previous_repo_count=$current_repo_count
  export current_repo_count=$(find . -type f -name $rosintall_filename | wc -l)

  if [ $loops_count -ge 0 ]; then
    export loops_count=$((loops_count - 1))
  else
    echo "Too many nested dependencies"
    exit 1
  fi

done

