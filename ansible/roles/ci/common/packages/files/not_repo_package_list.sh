#!/usr/bin/env bash

export ros_workspace=$1
export repo_sources_path=$2

export result=""
export has_packages=0

for workspace_file in $(find $ros_workspace -type f -name 'package.xml');
do

    export is_repo_file=0

    for repo_file in $(find $repo_sources_path -type f -name 'package.xml');
    do
        if [ $repo_file == $workspace_file ]; then
            export is_repo_file=1
            break
        fi
    done

    if [ $is_repo_file -eq 0 ]; then

        if [ $has_packages -eq 1 ]; then
            export result="$result;"
        fi
        export package_name=$(grep -e '<name>' $workspace_file | sed -e 's,.*<name>\([^<]*\)</name>.*,\1,g')
        export result="$result$package_name"
        export has_packages=1

    fi
done

echo "$result"
