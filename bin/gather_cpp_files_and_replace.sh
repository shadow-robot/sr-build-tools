#!/bin/bash
list_of_private_repos=()

Gather_Private_Repos () {
    cwd= pwd
    cd $1
    for repo in $(find . -maxdepth 1 -type d -printf '%f\n') 
    do
        repo="$1/$repo"
        cd $repo
        if [ -d ".git" ]
        then
            git config --global --add safe.directory $repo
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
        # Find the licence block which is between // Licence block start and  // Licence block end
        # and replace 'int licence = 0;' with 'int licence = licence_check();'
        sed -i '/\/\/ Licence block start/,/\/\/ Licence block end/{/int licence = 0;/s/int licence = 0;/int licence = licence_check();/}' $dir
    done
}

Gather_Private_Repos $1
for repo in ${list_of_private_repos[@]}
do
    Find_And_Replace_Licence_Var $repo
done
