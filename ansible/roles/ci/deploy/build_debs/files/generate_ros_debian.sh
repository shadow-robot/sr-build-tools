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
#set -x # echo commands run

export package_directory=$1
export ros_release=${2:-indigo}
export ubuntu_version_name=${3:-trusty}

pushd ${package_directory}

source <(grep '^export\|^source' ~/.bashrc)

bloom-generate rosdebian --os-name ubuntu --os-version ${ubuntu_version_name} --ros-distro ${ros_release} --place-template-files

export git_revision_number=`git rev-list HEAD | wc -l`

grep -rl --include "*.em" "@(change_version)" . | xargs sed -i "s/@(change_version)/@(change_version).${git_revision_number}/g"

bloom-generate rosdebian --os-name ubuntu --os-version ${ubuntu_version_name} --ros-distro ${ros_release} --process-template-files

popd