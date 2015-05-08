#!/usr/bin/env bash

mkdir -p ~/workspace
cd ~/workspace

git clone https://github.com/shadow-robot/sr-build-tools.git
cd ./sr-build-tools
git checkout F_hosted_build_support

./hosted/init_ros_indigo_ubuntu_14.sh
./hosted/pull_project_changes.sh https://raw.githubusercontent.com/AndriyPt/ros-cpp-samples/indigo-devel/tooro/tooro.rosinstall
./hosted/build.sh
./hosted/run_unit_tests.sh
