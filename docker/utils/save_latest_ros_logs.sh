#!/bin/bash

set -e # fails on errors
#set -x # echo commands run

GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo You are about to save latest ros logs, please add a note with reasons
read notes_from_user

container_name=$(sudo docker ps | awk '{if(NR>1) print $NF}')
dir=ros_logs_$(date +%Y-%m-%d)
timestamp=$(date +%Y-%m-%d-%T)

mkdir -p ~/$dir
docker cp -L $container_name:home/user/.ros/log/latest ~/$dir

mv ~/$dir/latest ~/$dir/ros_log_$timestamp
echo $notes_from_user > ~/$dir/ros_log_$timestamp/notes_from_user.txt

echo -e "${GREEN} Latest ROS Logs Saved! ${NC}"
sleep 5