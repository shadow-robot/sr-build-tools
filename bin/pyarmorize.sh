#!/bin/bash

echo "Installing pyarmor..."
sudo apt update
sudo apt install python-pip
sudo pip install pyarmor

echo "Finding all repos..."
list_of_repos=($(find . -name .git -type d -prune | sed 's#^\([^/]*/\([^/]*\)/.*\)#\2#'))

echo "Finding all private repos..."
list_of_private_repos=()

for repo in "${list_of_repos[@]}"
do
   cd $repo
   repo_https_url=$(git remote -v | awk '{print $2}' | sed 's/git@github.com:/https:\/\/github.com\//g' | head -n 1 | sed 's/\.git//g')
   cd ..
   return_code=$(curl -o /dev/null --silent --head --write-out '%{http_code}\n' $repo_https_url)
   if [ $return_code -ne 200 ]
      then
      list_of_private_repos+=($repo)
   fi
done

echo "Finding dirs containing python files..."
list_of_dirs_with_private_py_files=()
for priv_repo in "${list_of_private_repos[@]}"
do
   cd $priv_repo
   list_of_dirs_with_private_py_files_per_repo=($(find . -name '*.py' -printf '%h\n' | sort -u | sed "s/\.\//\.\/${priv_repo}\//g"))
   list_of_dirs_with_private_py_files+=( "${list_of_dirs_with_private_py_files_per_repo[@]}" )
   cd ..
done

echo "Obfuscating files..."
for dir in "${list_of_dirs_with_private_py_files[@]}"
do
   echo $dir
   pushd $dir
   pyarmor obfuscate .
   rm *.py
   mv ./dist/* .
   rm -rf dist
   chmod +x *.py
   popd
done

echo "Pyarmorize: done."
