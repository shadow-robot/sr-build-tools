#!/bin/bash
set -e

# setup ros environment
source "/installed_workspace/setup.bash"
roslaunch sr_robot_launch sr_right_ur10arm_hand.launch gui:=false
