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
    docker exec $current_container_name bash -c "rm /home/user/.ros/log/std*.log" || true
    docker exec $current_container_name bash -c "cp /home/user/.ros/log/core_dumps/* /home/user/logs_temp/" || true
    docker exec $current_container_name bash -c "rm /home/user/.ros/log/core_dumps/core_*" || true
    docker exec $current_container_name bash -c "cp /home/user/.ros/log/latest/* /home/user/logs_temp/"  || true

    docker exec $current_container_name bash -c "cp $latestbag /home/user/logs_temp/"  || true
    docker exec $current_container_name bash -c "cp $latestparam /home/user/logs_temp/"  || true
    docker exec $current_container_name bash -c "cp $latestws /home/user/logs_temp/"  || true
    docker cp -L ${ros_log_dir}/$dir/ros_log_$timestamp/notes_from_user.txt $current_container_name:/home/user/logs_temp/
    docker cp -L ${ros_log_dir}/$dir/ros_log_$timestamp/container_info.txt $current_container_name:/home/user/logs_temp/
    docker cp -L ${ros_log_dir}/$dir/ros_log_$timestamp/image_info.txt $current_container_name:/home/user/logs_temp/
}
function copy_to_host
{
    echo "Copying logs to host..."
    docker cp -L $current_container_name:/home/user/logs_temp ${ros_log_dir}/$dir/ros_log_$timestamp/
    mv ${ros_log_dir}/$dir/ros_log_$timestamp/logs_temp/* ${ros_log_dir}/$dir/ros_log_$timestamp/
    rm -rf ${ros_log_dir}/$dir/ros_log_$timestamp/logs_temp
}

container_name=$(docker ps | awk '{if(NR>1) print $NF}')

echo -e "${NC}${normal}You are about to save latest ros logs ${normal}${NC}"
echo -e "${YELLOW}${bold}WARNING! This closes all running docker containers. Do you wish to continue? (Y/n) ${normal}${NC}"
read prompt

if [[ $prompt == "n" || $prompt == "N" || $prompt == "no" || $prompt == "No" || $prompt == "NO" ]]; then
    exit 1
fi

echo -e "${NC}${normal}Please add a note for logging with reasons... ${normal}${NC}"
read notes_from_user

if [ "$(docker exec ${container_name} bash -c 'ls /usr/local/bin/customer.key')" ]; then
    save_log_msg_config_file="/home/$USER/.shadow_save_log_app/save_sr_log_msg_config.cfg"
    tmp_save_log_msg_config_file="/home/$USER/.shadow_save_log_app/tmp_save_sr_log_msg_config.cfg"

    if [ -f $save_log_msg_config_file ]; then
        # check if the file contains something we don't want
        if egrep -q -v '^#|^[^ ]*=[^;&]*' "$save_log_msg_config_file"; then
          echo "Config file is unclean, cleaning it..." >&2
          # filter the original to a tmp file
          egrep '^#|^[^ ]*=[^;&]*'  "$configfile" > "$tmp_save_log_msg_config_file"
          mv $tmp_save_log_msg_config_file $save_log_msg_config_file
        fi
    else
        touch $save_log_msg_config_file
        echo 'do_not_show_upload_log_message="false"' >> $save_log_msg_config_file
        echo 'upload_sr_log_messages="true"' >> $save_log_msg_config_file
    fi

    source $save_log_msg_config_file

    if [ ! $do_not_show_upload_log_message == "true" ]; then
        counter=0
        while ! [[ $upload_to_server == "Y" || $upload_to_server == "y" || $upload_to_server == "yes" || $upload_to_server == "YES" || $upload_to_server == "N" || $upload_to_server == "n" || $upload_to_server == "no" || $upload_to_server == "NO" ]]; do
            if [ $counter -gt 4 ]; then
                echo -e "${RED}Too many invalid inputs. Exiting the program...${normal}${NC}"
                sleep 5
                exit 1
            fi
            echo -e "${YELLOW}We are going to upload logs to Shadow servers so we can diagnose problems. Do you want to do this? (Y/n) ${normal}${NC}"
            read upload_to_server
            if ! [[ $upload_to_server == "Y" || $upload_to_server == "y" || $upload_to_server == "yes" || $upload_to_server == "YES" || $upload_to_server == "N" || $upload_to_server == "n" || $upload_to_server == "no" || $upload_to_server == "NO" ]]; then
                echo "Please type 'Y' or 'n'"
            fi
            let counter+=1
        done
        echo -e "${YELLOW}If you don't want to see the previous message again, type 'Y'. Otherwise, type 'n' (Y/n) ${normal}${NC}"
        read dont_show_upload_log_message

        if [[ $dont_show_upload_log_message == "Y" || $dont_show_upload_log_message == "Yes" || $dont_show_upload_log_message == "y" || $dont_show_upload_log_message == "YES" || $show_upload_log_message == "NO" ]]; then
            sed -i 's/\(do_not_show_upload_log_message *= *\).*/\1"true"/' $save_log_msg_config_file
        else
            sed -i 's/\(do_not_show_upload_log_message *= *\).*/\1"false"/' $save_log_msg_config_file
        fi

        if [[ $upload_to_server == "N" || $upload_to_server == "No" || $upload_to_server == "n" || $upload_to_server == "no" || $upload_to_server == "NO" ]]; then
            sed -i 's/\(upload_sr_log_messages *= *\).*/\1"false"/' $save_log_msg_config_file
            upload_sr_log_messages="false"
        else
            sed -i 's/\(upload_sr_log_messages *= *\).*/\1"true"/' $save_log_msg_config_file
            upload_sr_log_messages="true"
        fi
    fi
fi

if [ ! -z "$container_name" ]; then
        container_array=($container_name)
        for container in ${!container_array[@]}; do
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
	        docker exec $current_container_name /ros_entrypoint.sh bash -c "rosnode kill /record" || true
            sleep 1
	        latestbag=$(docker exec $current_container_name bash -c 'ls -dtr /home/user/*.bag | tail -1') || true
            echo "Copying logs from $current_container_name..."
            mkdir -p ${ros_log_dir}/$dir/ros_log_$timestamp
            echo $notes_from_user > ${ros_log_dir}/$dir/ros_log_$timestamp/notes_from_user.txt
            core_name=$(docker exec $current_container_name bash -c "ls /home/user/.ros/log/core_dumps/core* | grep -v '\.log' | awk '{if(NR>0) print $NF}'")
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

            # get container and image info
            container_image=$(docker ps -a | grep $current_container_name | awk '{print $2}' | tail -1)
            docker container inspect $current_container_name > ${ros_log_dir}/$dir/ros_log_$timestamp/container_info.txt
            docker images $container_image > ${ros_log_dir}/$dir/ros_log_$timestamp/image_info.txt

            if [ ${customerkey} ]; then
             # check if the folder is empty.
                if [ ! -z "$(docker exec ${container_name} bash -c 'find /home/user/logs_temp -maxdepth 0 -type d 2>/dev/null')" ]; then
                    echo -e "${YELLOW}${bold}There are previous logs that havent been sent yet. Would you like to send them now? Type 'Y' to send or 'n' to ignore and overwrite them ${normal}${NC}"
                    read old_logs
                    if [[ $old_logs == "y" || $old_logs == "Y" || $old_logs == "yes" || $old_logs == "Yes" || $old_logs == "YES" ]]; then
                        echo "Uploading to AWS - Please wait..."
                        upload_command=$(docker exec $current_container_name bash -c "source /usr/local/bin/shadow_upload.sh ${customerkey} /home/user/logs_temp $timestamp" || true) 
                        if [[ $upload_command == "ok" ]]; then
                            echo -e "${GREEN} Previous logs Uploaded to AWS for $current_container_name! ${NC}"
                        else
                            echo -e "${RED}${bold} Failed to upload previous logs to AWS for $current_container_name! Check your internet connection and try again. Exiting... ${normal}${NC}"
                            sleep 5
                            exit 1
                        fi
		                sleep 1
                    fi
                    # delete temp folder
                    docker exec $current_container_name bash -c "rm -rf /home/user/logs_temp"
                fi
                # copy new logs to temp folder
                copy_logs
                copy_to_host
                if [ $upload_sr_log_messages == "true" ]; then
                    echo "Uploading to AWS - Please wait..."
                    upload_command=$(docker exec $current_container_name bash -c "source /usr/local/bin/shadow_upload.sh ${customerkey} /home/user/logs_temp $timestamp" || true)
                    if [[ $upload_command == "ok" ]]; then
                        # delete temp folder
                        docker exec $current_container_name bash -c "rm -rf /home/user/logs_temp"
                        echo -e "${GREEN} Latest Logs Saved and Uploaded to AWS for $current_container_name! ${NC}"
                    else
                        echo -e "${RED}${bold} Failed to upload logs to AWS for $current_container_name! Check your internet connection and try again.${normal}${NC}"
                        sleep 5
                        exit 1
                    fi
                    sleep 1
                fi
            else
                copy_logs
                copy_to_host
                docker exec $current_container_name bash -c "rm -rf /home/user/logs_temp"
                echo -e "${GREEN} Latest Logs Saved for $current_container_name! ${NC}"
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
