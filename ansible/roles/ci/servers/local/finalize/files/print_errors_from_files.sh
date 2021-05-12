#!/bin/bash
#set -x # echo commands run

export directory=$1
cd $directory

error_count=0
unit_test_file_count=0
unit_test_files_with_errors=0

IFS=$'\n' # Allows for filenames with spaces
for file_path in $(find . -type f); do
    (( unit_test_file_count++))
    error_found=$(grep -Po '<failure|<error' "$file_path")
    if [[ ! -z ${error_found} ]]; then
        (( unit_test_files_with_errors++ ))
        lines_in_cdata=($(grep -Pzo '(?s)CDATA\[(.*?)\]\]' $file_path | sed 's/CDATA\[//g' | sed 's/\]\]/\n/g' | sed 's/\x0//g'))
        for (( i=0; i<${#lines_in_cdata[@]}; i++ )); do
            done_processing=$(echo ${lines_in_cdata[$i]} | grep -Po '^Done processing.*')
            total_errors_found=$(echo ${lines_in_cdata[$i]} | grep -Po '^Total errors found.*')
            new_error_line=$(echo ${lines_in_cdata[$i]} | grep -Po '^/.*')
            if [[ ! -z ${new_error_line} ]]; then
                (( error_count++ ))
                cleaned_up_error=$(echo ${lines_in_cdata[$i]} | sed 's/\/home.*shadow-robot\///' | sed 's/\*\*\*\*\*\*.*//' )
                echo -e "\nError $error_count in $cleaned_up_error"
            else
                if [[ -z ${done_processing} ]] && [[ -z ${total_errors_found} ]]; then
                    echo -e "${lines_in_cdata[$i]}"
                fi
            fi
        done
    fi
done
echo -e "\nTotal unit test errors: $error_count"
if [[ $error_count == 0 ]]; then
    echo -e "\nAll unit tests passed"
    exit 0
else
    echo -e "\nBuild failed because at least 1 unit test failed, see above for the exact error(s)"
    exit 1
fi
