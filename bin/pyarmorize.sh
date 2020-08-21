#!/bin/bash

set -e

workspace_path=$1

# echo "Building with catkin_make_isolated"
# cd $PROJECTS_WS/base
# source devel/setup.bash
# catkin_make_isolated
# cd

# find all repos
list_of_repos=()
echo "Finding all repos..."
cd $workspace_path/src
list_of_repos+=($(find . -name .git -type d -prune | sed 's#^\([^/]*/\([^/]*\)/.*\)#\2#'))
cd

# get all ros packages
list_of_ros_packages=($(rospack list-names))
list_of_private_packages=()

echo "Finding all private repos and packages..."
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

echo "Private repos found:"
for repo in "${list_of_private_repos[@]}"
do
   echo $repo
done

echo "Private packages found:"
for package in "${list_of_private_packages[@]}"
do
   echo $package
done

# install private packages
list_of_private_packages_as_string=$(printf " %s" "${list_of_private_packages[@]}")
list_of_private_packages_as_string=${list_of_private_packages_as_string:1}
echo $list_of_private_packages_as_string
cd $workspace_path
sudo bash -c "source devel/setup.bash && catkin_make_isolated --install --install-space /opt/ros/melodic --pkg $list_of_private_packages_as_string"

# # remove build and devel

sudo rm -rf ./devel ./build ./devel_isolated ./build_isolated

# removing source code
cd src
for repo in "${list_of_private_repos[@]}"
do
   rm -rf $repo
   wstool remote $repo
done

# find dirs in /opt/ros/melodic corresponding to private repos

# obfuscate py files



# echo "Installing pyarmor..."
# sudo apt update
# sudo apt install python-pip
# sudo pip install pyarmor

# echo "Finding all repos..."
# list_of_repos=($(find . -name .git -type d -prune | sed 's#^\([^/]*/\([^/]*\)/.*\)#\2#'))


# echo "Finding dirs containing python files..."
# list_of_dirs_with_private_py_files=()
# for priv_repo in "${list_of_private_repos[@]}"
# do
#    cd $priv_repo
#    list_of_dirs_with_private_py_files_per_repo=($(find . -name '*.py' -printf '%h\n' | sort -u | sed "s/\.\//\.\/${priv_repo}\//g"))
#    list_of_dirs_with_private_py_files+=( "${list_of_dirs_with_private_py_files_per_repo[@]}" )
#    cd ..
# done

# echo "Obfuscating files..."
# for dir in "${list_of_dirs_with_private_py_files[@]}"
# do
#    echo $dir
#    pushd $dir
#    pyarmor obfuscate .
#    rm *.py
#    mv ./dist/* .
#    rm -rf dist
#    chmod +x *.py
#    popd
# done

# echo "Pyarmorize: done."
