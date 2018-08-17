#!/bin/bash

set -e # fails on errors
#set -x # echo commands run

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
bold=$(tput bold)
normal=$(tput sgr0)

echo -e "${NC}${normal}You are about to save latest ros logs ${normal}${NC}"

echo -e "${RED}${bold}WARNING! This closes all running docker containers. Do you wish to continue? (y/n) ${normal}${NC}"
read prompt

if [[ $prompt == "" || $prompt == "n" || $prompt == "N" || $prompt == "no" || $prompt == "No" || $prompt == "NO" ]]; then
    exit 1
fi

echo -e "${NC} ${normal}Please add a note for logging with reasons... ${normal}${NC}"
read notes_from_user

container_name=$(docker ps | awk '{if(NR>1) print $NF}')

if [ ! -z "$container_name" ]; then
        container_array=($container_name)
        for container in ${!container_array[@]}; do
            current_container_name=${container_array[$container]}
            ros_log_dir=~/Desktop/ROS_LOGS/$current_container_name
            dir=ros_logs_$(date +%Y-%m-%d)
            timestamp=$(date +%Y-%m-%d-%T)
            latestws=$(docker exec $current_container_name bash -c 'ls -dtr /home/user/wsdiff_ws_diff* | tail -1')
            latestparam=$(docker exec $current_container_name bash -c 'ls -dtr /home/user/run_params* | tail -1')
	        docker exec $current_container_name bash -c "rosnode kill /record" || true
            sleep 1
	        latestbag=$(docker exec $current_container_name bash -c 'ls -dtr /home/user/*.bag | tail -1') || true
            echo "Copying logs from $current_container_name..."
            mkdir -p ${ros_log_dir}/$dir/ros_log_$timestamp
            core_name=$(docker exec $current_container_name bash -c "ls -I '*.log' /home/user/.ros/log/core_dumps/core* | awk '{if(NR>0) print $NF}'")
            if [ ! -z "$core_name" ]; then
                core_array=($core_name)
                for core in ${!core_array[@]}; do
                    current_core=${core_array[$core]}
                    current_runtime=$(docker exec $current_container_name bash -c "echo $current_core | grep -o -P '(?<=core_BOF_).*(?=_EOF_)'")
                    runtime_name=$(docker exec $current_container_name bash -c "strings $current_core | grep $current_runtime | tail -1")
                    #use runtime name in the log file to use later
                    docker exec $current_container_name bash -c "echo 'Executable:' $runtime_name > $current_core.log" || true
                    #extract readable info to log file
                    docker exec $current_container_name bash -c "gdb --core=$current_core $runtime_name -ex 'bt full' -ex 'quit' >> $current_core.log" || true
                done
            fi
            docker cp  -L $current_container_name:/home/user/.ros/log/stderr.log ${ros_log_dir}/$dir/ros_log_$timestamp || true
            docker cp  -L $current_container_name:/home/user/.ros/log/stdout.log ${ros_log_dir}/$dir/ros_log_$timestamp || true
            docker exec $current_container_name bash -c "rm /home/user/.ros/log/std*.log" || true
            docker cp  -L $current_container_name:/home/user/.ros/log/core_dumps ${ros_log_dir}/$dir/ros_log_$timestamp  || true
            docker exec $current_container_name bash -c "rm /home/user/.ros/log/core_dumps/core_*" || true
            echo "Killing container $current_container_name..."
            docker kill $current_container_name
            docker cp -L $current_container_name:home/user/.ros/log/latest ${ros_log_dir}/$dir
            mv ${ros_log_dir}/$dir/latest/*.* ${ros_log_dir}/$dir/ros_log_$timestamp
            rm -rf ${ros_log_dir}/$dir/latest
	        echo $notes_from_user > ${ros_log_dir}/$dir/ros_log_$timestamp/notes_from_user.txt
            docker container inspect $current_container_name > ${ros_log_dir}/$dir/ros_log_$timestamp/container_info.txt
            container_image=$(docker ps -a | grep $current_container_name| awk '{print $2}')
            docker images $container_image > ${ros_log_dir}/$dir/ros_log_$timestamp/image_info.txt
            docker cp -L $current_container_name:$latestws ${ros_log_dir}/$dir/ros_log_$timestamp || true
            docker cp -L $current_container_name:$latestparam ${ros_log_dir}/$dir/ros_log_$timestamp || true
            docker cp -L $current_container_name:$latestbag ${ros_log_dir}/$dir/ros_log_$timestamp || true

            echo -e "${GREEN} Latest ROS Logs Saved for $current_container_name! ${NC}"
            sleep 1
        done
else
    echo -e "${RED}There is no docker container running, please start a container to save logs${NC}"
    sleep 1
    exit 1
fi

echo -e "${GREEN}${bold}All ROS logs have been successfully saved!${normal}${NC}"
sleep 2
