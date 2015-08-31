#!/usr/bin/env bash

export ros_release=$1
export ros_workspace=$2
export package_name=$3
export errors_file_name=$4

source /opt/ros/$ros_release/setup.bash

echo "Executing delete for $ros_workspace/build and $ros_workspace/devel"
rm -rf $ros_workspace/build
rm -rf $ros_workspace/devel

cd $ros_workspace

export packages_errors_file=$ros_workspace/packages_errors_file.txt
printf "\nPackage $package_name\n\nvvvvvvvvvvvvvvvv\n\n" > $packages_errors_file

catkin_make --pkg $package_name 2>> $packages_errors_file

if [ $? -ne 0 ]; then
    cat $packages_errors_file >> $errors_file_name
    rm -f $packages_errors_file
    exit 1
else
    rm -f $packages_errors_file
    exit 0
fi
