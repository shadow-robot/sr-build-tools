#!/usr/bin/env bash

source /opt/ros/indigo/setup.bash
source ~/workspace/devel/setup.bash

env

locate rdf_loader.h

cd ~/workspace
catkin_make clean
catkin_make

