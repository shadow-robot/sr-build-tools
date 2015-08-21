#!/bin/bash
source ~/workspace/devel/setup.bash
source $(rosstack find sr_config)/../bashrc/env_variables.bashrc
roslaunch sr_robot_launch left_srhand_ur10arm.launch sim:=false