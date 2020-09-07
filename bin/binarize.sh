#!/bin/bash

set -e

workspace_path=$1
user_name=$2
# pyarmor_license_zip_file_path=$3

source $workspace_path/devel/setup.bash

echo "Running binarization script on workspace: $workspace_path"

echo "Installing pyarmor"
apt update
apt install python-pip
pip install pyarmor
# pyarmor register $pyarmor_license_zip_file_path
pyarmor runtime --output "/opt/ros/melodic/lib/python2.7/dist-packages"
if [ -f $HOME/.pyarmor_capsule.zip ]; then
    rm $HOME/.pyarmor_capsule.zip
fi

echo "Building with catkin_make_isolated"
cd $workspace_path
catkin_make_isolated
cd

echo "finding all repos in workspace"
list_of_repos=()
echo "Finding all repos..."
cd $workspace_path/src
list_of_repos+=($(find . -name .git -type d -prune | sed 's#^\([^/]*/\([^/]*\)/.*\)#\2#'))
cd

echo "Finding all ros packages"
list_of_ros_packages=($(rospack list-names))
list_of_private_packages=()

echo "Finding all private repos and packages"
list_of_private_repos=()

cd $workspace_path/src
for repo in "${list_of_repos[@]}"
do
   cd $repo
   repo_https_url=$(git remote -v | awk '{print $2}' | sed 's/git@github.com:/https:\/\/github.com\//g' | head -n 1 | sed 's/\.git//g')
   return_code=$(curl -o /dev/null --silent --head --write-out '%{http_code}\n' $repo_https_url)
   if [ $return_code -ne 200 ]
      then
      list_of_private_repos+=($repo)
      list_of_subfolders_in_repo=($(ls -d */ | sed 's:/*$::'))
      for folder in "${list_of_subfolders_in_repo[@]}"
      do
         if [[ " ${list_of_ros_packages[@]} " =~ " ${folder} " ]]; then
         list_of_private_packages+=($folder)
         fi
      done

   fi
   cd ..
done

list_of_private_packages_as_string=$(printf " %s" "${list_of_private_packages[@]}")
list_of_private_packages_as_string=${list_of_private_packages_as_string:1}

if [ -z "$list_of_private_packages_as_string" ]
then
   echo "No private packages in the workspace."
   echo "Binarize: done."
   exit 0
fi

echo "Private repos found:"
for repo in "${list_of_private_repos[@]}"
do
   echo "  - $repo"
done

echo "Private packages found:"
for package in "${list_of_private_packages[@]}"
do
   echo "  - $package"
done

echo "Installing private packages"
cd $workspace_path
catkin_make_isolated --install --install-space /opt/ros/melodic --pkg $list_of_private_packages_as_string

echo "Removing build and devel directories"

rm -rf ./devel ./build ./devel_isolated ./build_isolated

echo "Removing source code"
cd src
for repo in "${list_of_private_repos[@]}"
do
   rm -rf $repo
   wstool remove $repo
done

echo "Removing headers if they were installed"
cd /opt/ros/melodic/include
for package in "${list_of_private_packages[@]}"
do
   if [ ! -d "$package" ]; then
      continue
   fi
   rm -rf "$package"
done

echo "Building public packages"
cd $workspace_path
gosu $user_name catkin_make -DCMAKE_BUILD_TYPE=RelWithDebInfo

echo "Running pyarmorize"
pyarmorize_paths=("/opt/ros/melodic/lib" "/opt/ros/melodic/lib/python2.7/dist-packages")
for pyarmorize_path in "${pyarmorize_paths[@]}"
do
   cd $pyarmorize_path
   for package in "${list_of_private_packages[@]}"
   do
      if [ ! -d "$package" ]; then
         continue
      fi

      python_files_no_py_extension=()
      cd $package

      python_files_no_py_extension+=($(find . -type f -not -name '*.py' -exec grep -R -I -P '^#!/usr/bin/env python|^#! /usr/bin/env python|^#!/usr/bin/python|^#! /usr/bin/python' -l {} \; | sed "s/\.\///g"))
      
      for file in "${python_files_no_py_extension[@]}"
      do
         mv $file "$file.py"
      done

      if [ -f "__init__.py" ]; then
         mkdir /tmp/tmp_init_file_dir
         mv __init__.py /tmp/tmp_init_file_dir
      fi

      python_files_in_current_dir=`ls -1 *.py 2>/dev/null | wc -l`
      if [ $python_files_in_current_dir -eq 0 ]
      then
         if [ -d "/tmp/tmp_init_file_dir" ]; then
            mv /tmp/tmp_init_file_dir/__init__.py .
            rm -rf /tmp/tmp_init_file_dir
         fi
         cd ..
         continue
      fi 

      pyarmor obfuscate --exact --no-runtime *.py
      rm *.py
      mv ./dist/* .
      rm -rf dist
      chmod +x *.py

      if [ -d "/tmp/tmp_init_file_dir" ]; then
         mv /tmp/tmp_init_file_dir/__init__.py .
         rm -rf /tmp/tmp_init_file_dir
      fi

      for file in "${python_files_no_py_extension[@]}"
      do
         mv "$file.py" $file
      done
      cd ..
   done
done

echo "Binarize: done."

