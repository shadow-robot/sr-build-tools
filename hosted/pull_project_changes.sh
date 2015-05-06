#!/usr/bin/env bash

source /opt/ros/indigo/setup.bash
source ~/workspace/devel/setup.bash

cd ~/workspace/src

# TODO Add check if file exists in URL
wstool merge $1
wstool update

# rosdep doesn't work with meta-packages. To avoid listing all the package names we can use --from-paths
# to install deps for all the packages in a directory
rosdep install --from-paths . --ignore-src --rosdistro indigo -y
