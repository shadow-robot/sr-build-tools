#!/bin/bash

export directory=$1
cd $directory

declare -A copyright_array
declare -A exclusion_array

file_extensions=(py c h cpp hpp)

copyright_array[py]="# Copyright"
exclusion_array[py]="__init__,setup.py"

copyright_array[c]="// ©,//©,//Copyright,// Copyright"
exclusion_array[c]=""

copyright_array[h]="// ©,//©,//Copyright,// Copyright"
exclusion_array[h]=""

copyright_array[cpp]="// ©,//©,//Copyright,// Copyright"
exclusion_array[cpp]=""

copyright_dict[hpp]="// ©,//©,//Copyright,// Copyright"
exclusion_dict[hpp]=""

for file_extension in "${file_extensions[@]}"; do
    for file_name in `find . -name "*.$file_extension" -type f`; do
        [[ "${exclusion_dict[$file_extension]}" =~ (^|[[:space:]])$x($|[[:space:]]) ]] && echo 'yes' || echo 'no'
        # Ignoring some pre-defined files 
        if [[ " ${exclusion_dict[*]} " == *" d "* ]]; then
        if [[ $file_name != *"__init__"* ]] && [[ $file_name != *"setup.py"* ]]; then
            copyright_line=$(grep "$copyright_str_python" $file_name)
        if [ "$copyright_line" == "" ]; then
            if [ $num_files_no_copyright_python == 0 ]; then
                echo "The following python files do not have copyright:"
            fi
            echo $file_name
            let "num_files_no_copyright_python++"
        fi
    fi
done

if [ $num_files_no_copyright != 0 ]; then
    echo "There is a total of $num_files_no_copyright files without copyright"
    exit 1
fi
echo "All files have copyright"
exit 0
