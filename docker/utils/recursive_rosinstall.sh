#!/usr/bin/env bash

path_to_repo=$1

if [ -f .rosinstall ]; then
  echo "Merging .rosinstall with existing workspace .rosinstall..."
else
  echo "Initialising workspace .rosinstall from rosinstall..."
  wstool init . 
fi

wstool merge -t . $path_to_repo/repository.rosinstall

echo "Recursively resolving source dependencies, dependency dependencies, etc..."
current_repo_count=$(find . -type f -name repository.rosinstall | wc -l)
previous_repo_count=0
loops_count=10
echo $current_repo_count
while [ $current_repo_count -ne $previous_repo_count ]; do
  find . -type f -name repository.rosinstall -exec wstool merge -y {} \;
  sed -i "/https/s/\//:/3; s/https:\/\/{{github_login}}:{{github_password}}/git/g; s/https:\/\//git@/g" .rosinstall
  wstool update --delete-changed-uris
  previous_repo_count=$current_repo_count
  current_repo_count=$(find . -type f -name repository.rosinstall | wc -l)
  if [ $loops_count -ge 0 ]; then
    loops_count=$((loops_count - 1))
  else
    echo "Too many nested dependencies"
    exit 1
  fi
done
echo "Source dependencies resolved."
echo "Installing binary dependencies..."
sudo apt-get update
rosdep install -i --from-paths -y .
