#!/bin/bash

source ${1}/devel_isolated/setup.bash
rosdep update
rosdep install --default-yes --all --ignore-src --skip-keys sr_ur_msgs --skip-keys cereal_port
