#!/bin/bash

hand_user_email="software@shadowrobot.com"

if [ -z "$ros_release" ]; then
    echo "ERROR: ros_release not set"
    #exit 10
    ros_release='hydro'
fi

#
# Boot strap the hand user, basically everything that needs to done as the hand
# user.
#

echo Setup git
git config --global user.name $USER
git config --global user.email $hand_user_email

echo Adding desktop icons and scripts
cp -r /vagrant/home_hand/* ~/

echo Update rosdep
source /opt/ros/$ros_release/setup.bash
rosdep update

#
# Setup ROS workspace with our source and compile
#
SR_WORKSPACE="$HOME/ws_$ros_release"
echo Setting up hand workspac: $SR_WORKSPACE
if [ -e "$SR_WORKSPACE" ]; then
    chmod -R a+w "$SR_WORKSPACE"
    rm -rf "$SR_WORKSPACE"
fi
mkdir -p "$SR_WORKSPACE/src"
cd "$SR_WORKSPACE/src"
catkin_init_workspace
cd ..
catkin_make
source devel/setup.bash

echo Getting shadow code
cd "$SR_WORKSPACE/src"
wstool init .
wstool merge "/opt/shadow/sr-build-tools/data/shadow_robot-$ros_release.rosinstall"
wstool update

cd $SR_WORKSPACE
echo Installing deps
rosdep install --default-yes --all --ignore-src
echo Compile
catkin_make

source $SR_WORKSPACE/devel/setup.bash

echo Setup bashrc
echo "source $SR_WORKSPACE/devel/setup.bash" >> ~/.bashrc

