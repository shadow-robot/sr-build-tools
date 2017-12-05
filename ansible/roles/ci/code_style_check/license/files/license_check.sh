#!/bin/bash

copyright_str="# Copyright"
num_files_no_copyright=0

for file_name in `find . -name "*.py" -type f`; do
    # Ignoring __init__ and setup files
    if [[ $file_name != *"__init__"* ]] && [[ $file_name != *"setup.py"* ]]; then
        copyright_line=$(grep "$copyright_str" $file_name)
        # echo $copyright_line
        if [ "$copyright_line" == "" ]; then
            if [ $num_files_no_copyright == 0 ]; then
                echo "The following python files do not have copyright:"
            fi
            echo $file_name
            let "num_files_no_copyright++"
        fi
    fi
done
if [ $num_files_no_copyright == 0 ]; then
    echo "All files have copyright"
    exit 0
else
    echo "There is a total of $num_files_no_copyright files without copyright"
    exit 1
fi