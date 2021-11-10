#!/bin/bash
list_of_private_repos=()

Gather_Private_Repos () {
    cwd= pwd
    cd $1
    for repo in $(ls -d) 
    do
        cd $repo
        if [ -d ".git" ]
        then
            repo_https_url=$(git remote -v | awk '{print $2}' | sed 's/git@github.com:/https:\/\/github.com\//g' | head -n 1 | sed 's/\.git//g')
            return_code=$(curl -o /dev/null --silent --head --write-out '%{http_code}\n' $repo_https_url)
            if [ $return_code -ne 200 ]
            then
                list_of_private_repos+=($repo)
            fi
        fi
    done
    cd $cwd
}

Find_And_Replace_Licence_Var () {
    directories=( $(find $1 -type f -name "*.cpp") )
    for dir in ${directories[@]} 
    do
        sed -i 's/bool LICENCE_ENABLED = false;/bool LICENCE_ENABLED = true;/g' $dir
    done
}

Gather_Private_Repos "/home/user/projects/shadow_robot/base/src/"
for repo in ${list_of_private_repos[@]}
do
    Find_And_Replace_Licence_Var $repo
done