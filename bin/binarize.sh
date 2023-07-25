#!/bin/bash

set -e

while [[ $# > 1 ]]
do
key="$1"

case $key in
    -w|--workspacepath)
    workspace_path="$2"
    shift
    ;;
    -p|--pyarmourzippath)
    pyarmor_license_zip_file_path="$2"
    shift
    ;;
    -l|--underlaydevelpath)
    underlay_devel_path="$2"
    shift
    ;;
    -u|--username)
    USER_NAME="$2"
    shift
    ;;
    -i|--installspace)
    install_space="$2"
    shift
    ;;
    -e|--excludelist)
    exclude_packages_list="$2"
    shift
    ;;
    --)
    shift
    break
    ;;
    *)
    # ignore unknown option
    ;;
esac
shift
done


if [ -z "${workspace_path}" ]; then
    echo "ERROR: --workspacepath | -w is required for this (binarize.sh) script to work. Exiting..."
    exit
fi


if [ -z "${pyarmor_license_zip_file_path}" ]; then
    pyarmor_license_zip_file_path="/home/user/pyarmor-regfile-1.zip"
fi


if [ -z "${install_space}" ]; then
    install_space="/opt/ros/shadow"
fi


# If no underlying workspace is specified, use the binary install space instead
if [ -z "${underlay_devel_path}" ]; then
    underlay_devel=${install_space}
else
    underlay_devel="${underlay_devel_path}/devel"
fi


# If the user to rebuild non-private workspace as is not specified, use the owner of it
if [ -z "${user_name}" ]; then
   user_name=$(stat -c '%U' $workspace_path)
fi


source $workspace_path/devel/setup.bash

echo "Running binarization script on workspace: $workspace_path"

echo "Installing pyarmor"
apt update
apt install python3-pip
pip install pyarmor==7.7.4
pyarmor register $pyarmor_license_zip_file_path
pyarmor runtime --output "/opt/ros/$ROS_DISTRO/lib/python3/dist-packages"
if [ -f $HOME/.pyarmor_capsule.zip ]; then
    rm $HOME/.pyarmor_capsule.zip
fi

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
   git config --global --add safe.directory $workspace_path/src/$repo
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

if [[ ! -d $install_space ]]; then
   echo "Creating private binary workspace at $install_space"
   mkdir $install_space
   cd $install_space
   rosws init $install_space /opt/ros/$ROS_DISTRO
   cp /opt/ros/$ROS_DISTRO/env.sh $install_space/.
fi

list_of_private_packages_as_string=$(printf " %s" "${list_of_private_packages[@]}")
list_of_private_packages_as_string=${list_of_private_packages_as_string:1}

if [ -z "$list_of_private_packages_as_string" ]
then
   dummy_name="sr_dummy"
   echo "No private packages in the workspace at $workspace_path."
   echo "Creating dummy package $dummy_name for private binary workspace."
   gosu $user_name mkdir -p $workspace_path/src/$dummy_name
   cd $workspace_path/src/$dummy_name
   gosu $user_name catkin_create_pkg $dummy_name
   list_of_private_packages_as_string="$dummy_name"
   list_of_private_repos+=($dummy_name)
fi

echo "Private repos found in $workspace_path:"
for repo in "${list_of_private_repos[@]}"
do
   echo "  - $repo"
done

echo "Private packages found in $workspace_path:"
for package in "${list_of_private_packages[@]}"
do
   echo "  - $package"
done

source $underlay_devel/setup.bash
cd $workspace_path
echo "Removing all old build artefacts from $workspace_path"
rm -rf ./devel ./build ./devel_isolated ./build_isolated ./install ./install_isolated
echo "Building private packages and dependencies in $workspace_path"
catkin_make_isolated --install --only-pkg-with-deps $list_of_private_packages_as_string
echo "Installing private packages from $workspace_path to $install_space"
catkin_make_isolated --install --install-space $install_space --pkg $list_of_private_packages_as_string

echo "Removing private build artefacts from $workspace_path"
rm -rf ./devel_isolated ./build_isolated ./install_isolated

echo "Removing private source code from $workspace_path"
cd src
for repo in "${list_of_private_repos[@]}"
do
   rm -rf $repo
   # Remove from .rosinstall (if present, hence "|| true")
   wstool remove $repo || true
done

echo "Building remaining public packages in $workspace_path"
cd $workspace_path
source $underlay_devel/setup.bash
gosu $user_name catkin_make -DCMAKE_BUILD_TYPE=RelWithDebInfo

echo "Running pyarmorize"
pyarmorize_paths=("$install_space/lib" "$install_space/lib/python3/dist-packages")
for pyarmorize_path in "${pyarmorize_paths[@]}"
do
   if [ -d $pyarmorize_path ]; then
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
            mkdir tmp_init_file_dir
            mv __init__.py ./tmp_init_file_dir
         fi

         python_files_in_current_dir=`ls -1 *.py 2>/dev/null | wc -l`
         if [ $python_files_in_current_dir -eq 0 ]
         then
            if [ -d "tmp_init_file_dir" ]; then
               mv ./tmp_init_file_dir/__init__.py .
               rm -rf ./tmp_init_file_dir
            fi
            cd ..
            continue
         fi 

         pyarmor obfuscate --exact --no-runtime *.py
         rm *.py
         mv ./dist/* .
         rm -rf dist
         chmod +x *.py

         if [ -d "tmp_init_file_dir" ]; then
            mv ./tmp_init_file_dir/__init__.py .
            rm -rf ./tmp_init_file_dir
         fi

         for file in "${python_files_no_py_extension[@]}"
         do
            mv "$file.py" $file
         done
         cd ..
      done
   fi
done

echo "Binarize: done."

