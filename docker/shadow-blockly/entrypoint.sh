#!/bin/bash
set -e

# setup ros environment
source "/workspace/blockly/install_isolated/setup.bash"
roslaunch robot_blockly robot_blockly.launch
