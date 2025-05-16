#!/usr/bin/env bash

# Copyright 2022 Shadow Robot Company Ltd.
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation version 2 of the License.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.



export ros_release=$1
export ros_workspace=$2
export package_name=$3
export errors_file_name=$4

source <(grep "^export\|^source" $HOME/.bashrc)

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
