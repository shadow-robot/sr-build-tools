#!/bin/bash

source ${1}/devel/setup.bash
rosdep update
rosdep install --default-yes --from-paths ${1}/src --ignore-src --skip-keys sr_ur_msgs --skip-keys cereal_port
