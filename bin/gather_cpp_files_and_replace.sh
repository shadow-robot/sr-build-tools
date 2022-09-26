#!/bin/bash
# Copyright 2022 Shadow Robot Company Ltd.
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation version 2 of the License.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

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
        sed -i "s/if (false \&\& licence_check() != 1)/if (true \&\& licence_check() != 1)/g" $dir
    done
}

Gather_Private_Repos $1
for repo in ${list_of_private_repos[@]}
do
    Find_And_Replace_Licence_Var $repo
done
