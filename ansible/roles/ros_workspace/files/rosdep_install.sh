#!/bin/bash

source ${1}/devel/setup.bash
rosdep fix-permissions
rosdep update
rosdep fix-permissions
rosdep install --default-yes --all --ignore-src --skip-keys sr_ur_msgs --skip-keys cereal_port
