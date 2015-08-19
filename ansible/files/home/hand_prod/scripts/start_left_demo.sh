#!/bin/bash
source ~/workspace/devel/setup.bash
source $(rosstack find sr_config)/../bashrc/env_variables.bashrc
rosrun sr_example sr_left_mix_examples_unsafe.py
