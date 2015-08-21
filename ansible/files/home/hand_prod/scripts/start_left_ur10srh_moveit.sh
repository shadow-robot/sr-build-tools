#!/bin/bash
source ~/workspace/devel/setup.bash
source $(rosstack find sr_config)/../bashrc/env_variables.bashrc
roslaunch left_sr_ur10_moveit_config moveit_planning_and_execution.launch load_robot_description:=false