#!/bin/bash

export directory=$1
cd $directory

function array_contains(array,value)
{
    IFS=","
    result=false
    for i in $(echo $array); do
        if [["$i"=="$value"]]; then
            result=true
    done
    echo $result
    unset IFS
}
declare -A copyright_dict
declare -A exclusion_dict

file_extensions=(py,c,h,cpp,hpp)

py_copyrights="# Copyright"
copyright_dict[py]=py_copyrights
py_exclusions="__init__,setup.py"
exclusion_dict[py]=py_exclusions

c_copyrights="// ©,//©,//Copyright,// Copyright"
copyright_dict[c]=c_copyrights
c_exclusions=""
exclusion_dict[c]=c_exclusions

h_copyrights="// ©,//©,//Copyright,// Copyright"
copyright_dict[h]=h_copyrights
h_exclusions=""
exclusion_dict[h]=h_exclusions

cpp_copyrights="// ©,//©,//Copyright,// Copyright"
copyright_dict[cpp]=cpp_copyrights
cpp_exclusions=""
exclusion_dict[cpp]=cpp_exclusions

hpp_copyrights="// ©,//©,//Copyright,// Copyright"
copyright_dict[hpp]=hpp_copyrights
hpp_exclusions=""
exclusion_dict[hpp]=hpp_exclusions

for file_extension in "${file_extensions[@]}"; do
    for file_name in `find . -name "*.$file_extension" -type f`; do
        [[ "${exclusion_dict[$file_extension]}" =~ (^|[[:space:]])$x($|[[:space:]]) ]] && echo 'yes' || echo 'no'
        # Ignoring some pre-defined files 
        if [[ " ${exclusion_dict[*]} " == *" d "* ]]; then
    echo "arr contains d"
fi
        if [[ $file_name != *"__init__"* ]] && [[ $file_name != *"setup.py"* ]]; then
    


for file_name in `find . -name "*.py" -type f`; do
    # Ignoring __init__ and setup files
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

for file_name in `find . -name "*.c" -o -name "*.h" -type f`; do
    copyright_line=$(grep "$copyright_str_c" $file_name)
    if [ "$copyright_line" == "" ]; then
        if [ $num_files_no_copyright_c == 0 ]; then
            echo "The following C (.h and .c) files do not have copyright:"
        fi
        echo $file_name
        let "num_files_no_copyright_c++"
    fi
done

for file_name in `find . -name "*.cpp" -o -name "*.h" -type f`; do
    # Ignoring __init__ and setup files
    if [[ $file_name != *"__init__"* ]] && [[ $file_name != *"setup.py"* ]]; then
        copyright_line=$(grep "$copyright_str" $file_name)
        if [ "$copyright_line" == "" ]; then
            if [ $num_files_no_copyright == 0 ]; then
                echo "The following python files do not have copyright:"
            fi
            echo $file_name
            let "num_files_no_copyright++"
        fi
    fi
done

if [ $num_files_no_copyright != 0 ]; then
    echo "There is a total of $num_files_no_copyright files without copyright"
    exit 1
fi
echo "All files have copyright"
exit 0
