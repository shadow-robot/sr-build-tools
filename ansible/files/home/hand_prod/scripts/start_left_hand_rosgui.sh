#!/bin/bash
source ~/workspace/devel/setup.bash
source $(rosstack find sr_config)/../bashrc/env_variables.bashrc
roslaunch sr_ethercat_hand_config lhand_gui.launch

