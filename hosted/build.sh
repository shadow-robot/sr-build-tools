#!/usr/bin/env bash

source /opt/ros/indigo/setup.bash
source ~/workspace/devel/setup.bash

cd ~/workspace
catkin_make clean
catkin_make

