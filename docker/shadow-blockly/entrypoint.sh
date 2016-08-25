#!/bin/bash
set -e

# setup ros environment
source "/workspace/blockly/devel/setup.bash"
roslaunch robot_blockly robot_blockly.launch block_packages:=[sr_blockly_blocks]
