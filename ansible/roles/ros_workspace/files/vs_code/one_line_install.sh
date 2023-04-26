#!/bin/bash

build_tools_dir=~/sr-build-tools
build_tools_branch=F_#SP-476_vs_code_setup_lint
# If build tools dir exists, back it up
if [ -d $build_tools_dir ]; then
    mv $build_tools_dir $build_tools_dir.bak
fi
git clone --depth 1 --single-branch -b $build_tools_branch https://github.com/shadow-robot/sr-build-tools.git $build_tools_dir
cp -r $build_tools_dir/ansible/roles/ros_workspace/files/vs_code/.vscode ~/projects/shadow_robot/base/.
echo "Run 'ROS: Update C++ Properties' command in VS Code to make C++ intellisense etc. work."
