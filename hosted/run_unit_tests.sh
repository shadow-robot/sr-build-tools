#!/usr/bin/env bash

source /opt/ros/indigo/setup.bash
source ~/workspace/devel/setup.bash

cd ~/workspace
catkin_make run_tests

mv -vt $SHIPPABLE_REPO_DIR/shippable/testresults/ ~/workspace/build/test_results/*
