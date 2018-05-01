#!/bin/bash

set -e # fails on errors
#set -x # echo commands run

echo You are about to save latest ros logs, please add a note with reasons
read notes_from_user

container_name=$(sudo docker ps | awk '{if(NR>1) print $NF}')
dir=ros_logs_$(date +%Y-%m-%d)
timestamp=$(date +%Y-%m-%d-%T)

mkdir -p ~/$dir
docker cp -L $container_name:home/user/.ros/log/latest ~/$dir

mv ~/$dir/latest ~/$dir/ros_log_$timestamp
echo $notes_from_user > ~/$dir/ros_log_$timestamp/notes_from_user.txt

