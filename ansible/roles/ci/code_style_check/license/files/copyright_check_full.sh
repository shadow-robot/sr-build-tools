#!/bin/bash

export directory=$1
cd $directory

filetypes=(py c h cpp hpp)

exclusions_py=("__init__" "setup.py")

exclusions_c=()

exclusions_h=()

exclusions_cpp=()

exclusions_hpp=()

year_regex="(([0-9]{4}){1}(-[0-9]{4})?)+(,([0-9]{4}){1}(-[0-9]{4})?)*"
copyrights_c_public="\*\n\* Copyright ${year_regex} Shadow Robot Company Ltd.\n\*\n\* This program is free software: you can redistribute it and\/or modify it\n\
\* under the terms of the GNU General Public License as published by the Free\n\
\* Software Foundation version 2 of the License.\n\
\*\n\
\* This program is distributed in the hope that it will be useful, but WITHOUT\n\
\* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or\n\
\* FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for\n\
\* more details.\n\
\*\n\
\* You should have received a copy of the GNU General Public License along\n\
\* with this program. If not, see <http://www.gnu.org/licenses/>.\n\
\*/"
copyrights_c_private="\/\*\n\* Copyright \(C\) ${year_regex} Shadow Robot Company Ltd - All Rights Reserved\. Proprietary and Confidential.\n\
\* Unauthorized copying of the content in this file, via any medium is strictly prohibited\.\n\
\*/"
copyrights_c_regex="(${copyrights_c_public})|(${copyrights_c_private})"
copyrights_h_regex=$copyrights_c_regex
copyrights_cpp_regex=$copyrights_c_regex
copyrights_hpp_regex=$copyrights_c_regex
copyrights_py_public="\# Copyright ${year_regex} Shadow Robot Company Ltd.\n\#\n\# This program is free software: you can redistribute it and\/or modify it\n\
# under the terms of the GNU General Public License as published by the Free\n\
# Software Foundation version 2 of the License\.\n\
#\n\
# This program is distributed in the hope that it will be useful, but WITHOUT\n\
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or\n\
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for\n\
# more details\.\n\
#\n\
# You should have received a copy of the GNU General Public License along\n\
# with this program\. If not, see <http://www.gnu.org/licenses/>\."
copyrights_py_private="# Copyright \(C\) ${year_regex} Shadow Robot Company Ltd - All Rights Reserved\. Proprietary and Confidential\.\n\
# Unauthorized copying of the content in this file, via any medium is strictly prohibited\."
copyrights_py_regex="(${copyrights_py_public})|(${copyrights_py_private})"

has_missing_copyrights=false
total_num_files_no_copyright=0
for filetype in "${filetypes[@]}"; do
    num_files_no_copyright=0
    exclusions_name="exclusions_$filetype"[@]
    exclusions=("${!exclusions_name}")
    copyrights_name="copyrights_${filetype}_regex"[@]
    copyrights=("${!copyrights_name}")
    for filename in $(find . -name "*.$filetype" -type f); do
        accept_file=true
        for exclusion in "${exclusions[@]}"; do
            if [[ $(echo -n $exclusion | wc -m) > 0 ]] && [[ $filename == *$exclusion* ]] ; then
                accept_file=false
            fi
        done
        has_copyright=false
        if $accept_file; then
            has_copyright=false
            for copyright in "${copyrights[@]}"; do
                grep -Pz "$copyright" "$filename" > /dev/null
                if [[ $? == 0 ]]; then
                    has_copyright=true
                fi
            done
            if ! $has_copyright; then
                echo $'\n'"$filename"
            (( num_files_no_copyright++ ))
            (( total_num_files_no_copyright++ ))
            has_missing_copyrights=true
            fi
        fi
    done
    if [ $num_files_no_copyright != 0 ]; then
        echo $'\n'"Copyright check failure: There are $num_files_no_copyright $filetype files without copyright. See above for a list of files"
    fi
done
if $has_missing_copyrights; then
    echo $'\n\n'"Copyright check failure: There are $total_num_files_no_copyright files in total without copyright. See above for details."
    exit 1
fi
exit 0
