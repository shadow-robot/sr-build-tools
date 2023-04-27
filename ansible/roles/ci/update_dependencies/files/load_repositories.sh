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
  wstool update --abort-changed-uris -j5

  export previous_repo_count=$current_repo_count
  export current_repo_count=$(find . -type f -name $rosintall_filename | wc -l)

  if [ $loops_count -ge 0 ]; then
    export loops_count=$((loops_count - 1))
  else
    echo "Too many nested dependencies"
    exit 1
  fi

done
