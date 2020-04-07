#!/bin/bash
RED='\033[1;31m'

export directory=$1
cd $directory

file_list_total=0
files_with_errors_total=0
declare -a file_error_dictionary

IFS=$'\n' # Allows for filenames with spaces
for file_path in $(find . -type f); do
    (( file_list_total++ ))
    grep -Pz '<failure|<error' "$file_path" > /dev/null
    if [[ $? != 0 ]]; then
        (( files_with_errors_total++ ))
        errors=$(grep -Pzo '(?s)CDATA\[(.*?)\]\]' "$file_path" | sed 's/CDATA\[//g' | sed 's/\]\]/\n/g' )
        echo $errors
    fi
done
