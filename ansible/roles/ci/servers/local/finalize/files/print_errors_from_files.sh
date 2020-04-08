#!/bin/bash
#set -x # echo commands run

RED='\033[1;31m'
NC='\033[0m' # No Color

export directory=$1
cd $directory

error_count=0

IFS=$'\n' # Allows for filenames with spaces
for file_path in $(find . -type f); do
    error_found=$(grep -Po '<failure|<error' "$file_path")
    if [[ ! -z ${error_found} ]]; then
        lines_in_cdata=($(grep -Pzo '(?s)CDATA\[(.*?)\]\]' $file_path | sed 's/CDATA\[//g' | sed 's/\]\]/\n/g' | sed 's/\x0//g'))
        for (( i=0; i<${#lines_in_cdata[@]}; i++ )); do
            done_processing=$(echo ${lines_in_cdata[$i]} | grep -Po 'Done processing.*')
            total_errors_found=$(echo ${lines_in_cdata[$i]} | grep -Po 'Total errors found.*')
            if [[ -z ${done_processing} ]] && [[ -z ${total_errors_found} ]]; then
                (( error_count++ ))
                cleaned_up_error=$(echo ${lines_in_cdata[$i]} | sed 's/\/home.*shadow-robot\///' )
                echo -e "${RED}error $error_count in $cleaned_up_error${NC}"
            fi
        done
    fi
done
echo "Total errors: $error_count"
