#!/bin/bash

source ${1}/devel/setup.bash
rosdep update
sudo rosdep install --default-yes --all --ignore-src --skip-keys sr_ur_msgs --skip-keys cereal_port
