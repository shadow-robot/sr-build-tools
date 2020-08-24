#!/bin/bash

set -e

# workspace_path=$1


# # echo "Installing pyarmor..."
# apt update
# apt install python-pip
# pip install pyarmor
# pyarmor runtime --output "$workspace_path/devel/lib/python2.7/dist-packages"
# if [ -f $HOME/.pyarmor_capsule.zip ]; then
#     rm $HOME/.pyarmor_capsule.zip
# fi

# # echo "Building with catkin_make_isolated"
# cd $workspace_path
# source devel/setup.bash
# catkin_make_isolated
# cd

# # find all repos
# list_of_repos=()
# echo "Finding all repos..."
# cd $workspace_path/src
# list_of_repos+=($(find . -name .git -type d -prune | sed 's#^\([^/]*/\([^/]*\)/.*\)#\2#'))
# cd

# # get all ros packages
# list_of_ros_packages=($(rospack list-names))
# list_of_private_packages=()

# echo "Finding all private repos and packages..."
# list_of_private_repos=()

# cd $workspace_path/src
# for repo in "${list_of_repos[@]}"
# do
#    cd $repo
#    repo_https_url=$(git remote -v | awk '{print $2}' | sed 's/git@github.com:/https:\/\/github.com\//g' | head -n 1 | sed 's/\.git//g')
#    return_code=$(curl -o /dev/null --silent --head --write-out '%{http_code}\n' $repo_https_url)
#    if [ $return_code -ne 200 ]
#       then
#       list_of_private_repos+=($repo)
#       list_of_subfolders_in_repo=($(ls -d */ | sed 's:/*$::'))
#       for folder in "${list_of_subfolders_in_repo[@]}"
#       do
#          if [[ " ${list_of_ros_packages[@]} " =~ " ${folder} " ]]; then
#          list_of_private_packages+=($folder)
#          fi
#       done

#    fi
#    cd ..
# done

# echo "Private repos found:"
# for repo in "${list_of_private_repos[@]}"
# do
#    echo $repo
# done

# echo "Private packages found:"
# for package in "${list_of_private_packages[@]}"
# do
#    echo $package
# done

# # install private packages
# list_of_private_packages_as_string=$(printf " %s" "${list_of_private_packages[@]}")
# list_of_private_packages_as_string=${list_of_private_packages_as_string:1}
# echo $list_of_private_packages_as_string
# cd $workspace_path
# source devel/setup.bash
# catkin_make_isolated --install --install-space /opt/ros/melodic --pkg $list_of_private_packages_as_string

# # # remove build and devel

# rm -rf ./devel ./build ./devel_isolated ./build_isolated

# # removing source code
# cd src
# for repo in "${list_of_private_repos[@]}"
# do
#    rm -rf $repo
#    wstool remove $repo
# done

# find dirs in /opt/ros/melodic corresponding to private repos

list_of_private_packages=("sr_teleop_vive_haptx_internal" "sr_fingertip_hand_teleop" )

cd /opt/ros/melodic/lib
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

   pyarmor obfuscate --no-runtime .
   rm *.py
   mv ./dist/* .
   rm -rf dist
   chmod +x *.py

   for file in "${python_files_no_py_extension[@]}"
   do
      mv "$file.py" $file
   done
   cd ..
done

echo "Pyarmorize: done."
