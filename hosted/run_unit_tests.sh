#!/usr/bin/env bash

source /opt/ros/indigo/setup.bash
source ~/workspace/devel/setup.bash

cd ~/workspace
catkin_make run_tests

mkdir -p ~/shippable/testresults
mkdir -p ~/shippable/codecoverage

mv ~/workspace/build/test_results/* ~/shippable/testresults

ls -al ~/shippable
ls -al ~/shippable/testresults
