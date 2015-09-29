#!/usr/bin/env bash

export ros_workspace=$1
export dependencies_file=$2

cd $ros_workspace/src

export rosintall_filename=$(basename "$dependencies_file")
export current_repo_count=$(find . -type f -name $rosintall_filename | wc -l)
export previous_repo_count=0
export loops_count=10

while [ $current_repo_count -ne $previous_repo_count ]; do

  find . -type f -name $rosintall_filename -exec wstool merge -a -y {} \;
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

