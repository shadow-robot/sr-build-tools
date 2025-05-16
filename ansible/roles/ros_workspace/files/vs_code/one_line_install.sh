#!/bin/bash

# Copyright 2023 Shadow Robot Company Ltd.
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

build_tools_dir=~/sr-build-tools
build_tools_branch=lint
# If build tools dir exists, back it up
if [ -d $build_tools_dir ]; then
    mv $build_tools_dir $build_tools_dir.bak
fi
git clone --depth 1 --single-branch -b $build_tools_branch https://github.com/shadow-robot/sr-build-tools.git $build_tools_dir
cp -r $build_tools_dir/ansible/roles/ros_workspace/files/vs_code/.vscode ~/projects/shadow_robot/base/.
echo "Run 'ROS: Update C++ Properties' command in VS Code to make C++ intellisense etc. work."
