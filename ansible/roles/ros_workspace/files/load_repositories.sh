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

set -e # fail on errors

recursive_rosinstall () {
    while [ $current_repo_count -ne $previous_repo_count ]; do
        find $current_folder -type f -name $rosinstall_filename -exec wstool merge -y {} \;
        sed -i "$1" .rosinstall

        mv .rosinstall repository.rosinstall
        wstool init --shallow . repository.rosinstall -j5

        export previous_repo_count=$current_repo_count
        export current_repo_count=$(find $destination_folder -type f -name $rosinstall_filename | wc -l)

        if [ $loops_count -ge 1 ]; then
            export loops_count=$((loops_count - 1))
        else
            break
        fi
        export current_folder=$destination_folder
    done
}

export initial_folder=$1
export destination_folder=$2
export levels_depth=$3
export use_ssh_uri=${4:-false}
export github_user=${5:-github_user_not_provided}
export github_password=${6:-github_password_not_provided}

export current_folder=$initial_folder
cd $destination_folder

wstool init .

export rosinstall_filename="repository.rosinstall"

export current_repo_count=$(find $destination_folder -type f -name $rosinstall_filename | wc -l)
export previous_repo_count=-1
export loops_count=$((levels_depth - 1))

if [ "${use_ssh_uri}" = true ]; then
    recursive_rosinstall "/https/s/\//:/3; s/https:\/\/{{github_login}}:{{github_password}}/git/g; s/https:\/\//git@/g"
else
    recursive_rosinstall "s/{{github_login}}/$github_user/g; s/{{github_password}}/$github_password/g"
fi

# Find and delete duplicate repository directories. Keep the one furthest from destination_folder, e.g. codebuild.
this_script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
$this_script_dir/deduplicate_repositories.py -p $destination_folder -v -w
