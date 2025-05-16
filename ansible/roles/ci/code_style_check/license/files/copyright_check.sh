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

export directory=$1
cd $directory

copyright_str="# Copyright"
num_files_no_copyright=0

for file_name in `find . -name "*.py" -type f`; do
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
