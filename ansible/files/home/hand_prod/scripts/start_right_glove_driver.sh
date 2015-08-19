#!/bin/bash
source ~/workspace/devel/setup.bash
source $(rosstack find sr_config)/../bashrc/env_variables.bashrc
roslaunch cyberglove_trajectory cyberglove.launch version:=1 filter:=false joint_prefix:=rh_ trajectory_tx_delay:=0.040
