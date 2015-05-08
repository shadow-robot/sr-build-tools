#!/usr/bin/env bash

source /opt/ros/indigo/setup.bash
source ~/workspace/devel/setup.bash

env

sudo find / -name "rdf_loader.h"

cd ~/workspace
catkin_make clean
catkin_make

