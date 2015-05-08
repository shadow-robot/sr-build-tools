#!/usr/bin/env bash

source /opt/ros/indigo/setup.bash
source ~/workspace/devel/setup.bash

cd ~/workspace
catkin_make run_tests

mkdir -p shippable/testresults
mkdir -p shippable/codecoverage

for dir in ~/workspace/build/test_results/*
do
    dir_name=$(basename "$dir")
    for file in "$dir"/*
    do

        if [[ -f $file ]]
        then
            filename=$(basename "$file")
#            mv -vT "$file" "shippable/testresults/${dir_name}_${filename}"
            mv -vT "$file" "shippable/testresults/nosetests.xml"
            mv -vT "$file" "$HOME/shippable/testresults/nosetests.xml"
        fi
    done
done

ls -al shippable
ls -al shippable/testresults

cd shippable
pwd
