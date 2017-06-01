#!/usr/bin/env bash

recursive_rosinstall () {
    while [ $current_repo_count -ne $previous_repo_count ]; do
        find $current_folder -type f -name $rosinstall_filename -exec wstool merge -y {} \; 
        sed -i "$1" .rosinstall
        wstool update --delete-changed-uris  -j5

        export previous_repo_count=$current_repo_count
        export current_repo_count=$(find $destination_folder -type f -name $rosinstall_filename | wc -l)

        if [ $loops_count -ge 1 ]; then
            export loops_count=$((loops_count - 1))
        else
            break
        fi
        export current_folder=$destination_folder
    done
}

export initial_folder=$1
export destination_folder=$2
export levels_depth=$3
export use_ssh_uri=${4:-false}
export github_user=${5:-github_user_not_provided}
export github_password=${6:-github_password_not_provided}

export current_folder=$initial_folder
cd $destination_folder

wstool init .

export rosinstall_filename="repository.rosinstall"

export current_repo_count=$(find $destination_folder -type f -name $rosinstall_filename | wc -l)
export previous_repo_count=-1
export loops_count=$((levels_depth - 1))

if [ "${use_ssh_uri}" = true ]; then
    recursive_rosinstall "/https/s/\//:/3; s/https:\/\/{{github_login}}:{{github_password}}/git/g; s/https:\/\//git@/g"
else
    recursive_rosinstall "s/{{github_login}}/$github_user/g; s/{{github_password}}/$github_password/g"
fi
