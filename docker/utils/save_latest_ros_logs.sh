#!/bin/bash

set -e # fails on errors
#set -x # echo commands run

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
bold=$(tput bold)
normal=$(tput sgr0)

            function copy_logs
            {
                # copy logs to temp folder
                docker exec $current_container_name bash -c "mkdir /home/user/logs_temp/" || true
                docker exec $current_container_name bash -c "cp /home/user/.ros/log/stderr.log /home/user/logs_temp/" || true
                docker exec $current_container_name bash -c "cp /home/user/.ros/log/stdout.log /home/user/logs_temp/" || true
                docker exec $current_container_name bash -c "rm /home/user/.ros/log/std*.log" || true
                docker exec $current_container_name bash -c "cp /home/user/.ros/log/core_dumps/* /home/user/logs_temp/" || true
                docker exec $current_container_name bash -c "rm /home/user/.ros/log/core_dumps/core_*" || true
                docker exec $current_container_name bash -c "cp /home/user/.ros/log/latest/*.* /home/user/logs_temp/"
                docker exec $current_container_name bash -c "cp $latestbag /home/user/logs_temp/"
                docker exec $current_container_name bash -c "cp $latestparam /home/user/logs_temp/"
                docker exec $current_container_name bash -c "cp $latestws /home/user/logs_temp/"
                docker cp  -L ${ros_log_dir}/$dir/ros_log_$timestamp/notes_from_user.txt $current_container_name:/home/user/logs_temp/
            }

if [ ${customerkey} = false ]; then
    echo -e "${NC}${normal}You are about to save latest ros logs ${normal}${NC}"
else
    echo -e "${NC}${normal}You are about to save and upload the latest ros logs to AWS (up to 200 MB) ${normal}${NC}"
fi

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
            customerkey=false
            if [ "$(docker exec ${container_name} bash -c 'ls /usr/local/bin/customer.key')" ]; then
                customerkey=$(docker exec ${container_name} bash -c "head -n 1 /usr/local/bin/customer.key")
            else
                customerkey=false
            fi
            current_container_name=${container_array[$container]}
            ros_log_dir=~/Desktop/ROS_LOGS/$current_container_name
            dir=ros_logs_$(date +%Y-%m-%d)
            timestamp=$(date +%Y-%m-%d-%T)
            latestws=$(docker exec $current_container_name bash -c 'ls -dtr /home/user/wsdiff_ws_diff* | tail -1')
            latestparam=$(docker exec $current_container_name bash -c 'ls -dtr /home/user/run_params* | tail -1')
	        echo "Killing rosmaster to make .bag.active file into .bag file"
	        docker exec $current_container_name bash -c "kill -SIGINT $(ps aux | grep 'rosmaster' | grep -v grep| awk '{print $2}')" || true
	        #if rosmaster is still running, use kill -9 to kill it
	        docker exec $current_container_name bash -c "kill -9 $(ps aux | grep 'rosmaster' | grep -v grep| awk '{print $2}') || echo 'rosmaster killed silently'" || true
	        latestbag=$(docker exec $current_container_name bash -c 'ls -dtr /home/user/*.bag | tail -1')
            echo "Copying logs from $current_container_name.."
            mkdir -p ${ros_log_dir}/$dir/ros_log_$timestamp
            echo $notes_from_user > ${ros_log_dir}/$dir/ros_log_$timestamp/notes_from_user.txt
            core_name=$(docker exec $current_container_name bash -c "ls -I '*.log' /home/user/.ros/log/core_dumps/core* | awk '{if(NR>0) print $NF}'")
            if [ ! -z "$core_name" ]; then
                core_array=($core_name)
                for core in ${!core_array[@]}; do
                    current_core=${core_array[$core]}
                    current_runtime=$(docker exec $current_container_name bash -c "echo $current_core | grep -o -P '(?<=core_BOF_).*(?=_EOF_)'")
                    runtime_name=$(docker exec $current_container_name bash -c "strings $current_core | grep $current_runtime | tail -1")
                    #use runtime name in the log file to use later
                    docker exec $current_container_name bash -c "echo 'Executable:' $runtime_name > $current_core.log"
                    #extract readable info to log file
                    docker exec $current_container_name bash -c "gdb --core=$current_core $runtime_name -ex 'bt full' -ex 'quit' >> $current_core.log"
                done
            fi
            
            # check if the folder is empty. if not then ask the user if he wants to upload the files. If not then delete them and start fresh and copy the new files. If yes then upload first and then copy the new files
            if [ ${customerkey} ]; then
             # check if the folder is empty.
                if [ -n "$(docker exec ${container_name} bash -c 'find /home/user/logs_temp -maxdepth 0 -type d -empty 2>/dev/null')" ]; then
                    echo "There are previous logs that havent been sent yet. Would you like to send them now? Type 'y' to send or 'n' to ignore and overwrite them"
                    read old_logs
                    if [[ $old_logs == "y" || $old_logs == "Y" || $old_logs == "yes" ]]; then
                        docker exec $current_container_name bash -c "source /usr/local/bin/shadow_upload.sh ${customerkey} /home/user/logs_temp /home/user/$timestamp"
                        
                    fi
                copy_logs
                echo "Empty directory"
            else

                copy_logs
                echo "Not empty or NOT a directory"
            fi
            fi

            
            
            
            # get container and image info
            container_image=$(docker ps -a | grep $current_container_name| awk '{print $2}')
            docker container inspect $current_container_name > ${ros_log_dir}/$dir/ros_log_$timestamp/container_info.txt
            docker images $container_image > ${ros_log_dir}/$dir/ros_log_$timestamp/image_info.txt
            # copy these files to container temp folder
            docker cp  -L ${ros_log_dir}/$dir/ros_log_$timestamp/container_info.txt $current_container_name:/home/user/logs_temp/
            docker cp  -L ${ros_log_dir}/$dir/ros_log_$timestamp/image_info.txt $current_container_name:/home/user/logs_temp/


	        if [ ${customerkey} = false ]; then
            # copy files from temp folder to host and empty the folder
                docker cp  -L $current_container_name:/home/user/logs_temp/*.* ${ros_log_dir}/$dir/ros_log_$timestamp/
                docker exec $current_container_name bash -c "rm /home/user/.ros/log/*.*"
	    	    echo -e "${GREEN} Latest ROS Logs Saved for $current_container_name! ${NC}"
                sleep 1
	        else
	    	    printf "#! /bin/bash
            	source /home/$USER/.shadow_save_log_app/save_latest_ros_logs/shadow_upload.sh ${customerkey} ${ros_log_dir}/$dir/ros_log_$timestamp"
	    	    echo -e "${GREEN} Latest ROS Logs Saved and Uploaded to AWS for $current_container_name! ${NC}"
		        sleep 1
	        fi
            
            echo "Killing container $current_container_name..."
            docker kill $current_container_name
        done
else
    echo -e "${RED}There is no docker container running, please start a container to save logs${NC}"
    sleep 1
    exit 1
fi

echo -e "${GREEN}${bold}All ROS logs have been successfully saved!${normal}${NC}"
sleep 5
